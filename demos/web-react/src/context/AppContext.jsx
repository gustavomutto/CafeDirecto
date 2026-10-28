import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { createSeed, SEED_VERSION } from '../data/seed';
import { AUTO_REPLIES, translate } from '../data/phrases';
import { langOf, other, uid } from '../utils';

const STORAGE_KEY = 'cafedirecto-demo';
const AppContext = createContext(null);

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const s = JSON.parse(raw);
      if (s && s.version === SEED_VERSION) return { ...s, syncing: false };
    }
  } catch {
    /* sin localStorage: se usa la semilla */
  }
  return createSeed();
}

export function AppProvider({ children }) {
  const [state, setState] = useState(loadState);
  const [toast, setToast] = useState(null);
  const stateRef = useRef(state);
  stateRef.current = state;
  // Respuestas automáticas que esperan a que vuelva la conexión
  const queuedWhileOffline = useRef([]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      /* ignorar */
    }
  }, [state]);

  // Aplica una mutación sobre una copia del estado
  const mutate = useCallback((fn) => {
    setState((s) => {
      const n = structuredClone(s);
      fn(n);
      return n;
    });
  }, []);

  const showToast = useCallback((text, icon = '✓') => {
    const id = uid('t');
    setToast({ id, text, icon });
    setTimeout(() => setToast((t) => (t && t.id === id ? null : t)), 2800);
  }, []);

  const role = state.role;
  const lang = langOf(role);
  const tr = useCallback((es, en) => (lang === 'es' ? es : en), [lang]);
  const pick = useCallback((obj) => (obj && typeof obj === 'object' ? obj[lang] ?? obj.es ?? obj.en : obj), [lang]);

  // ── Helpers internos ──────────────────────────────────────────────
  const isDemoPair = (conv, s) => conv.farmId === s.me.farmer && conv.buyerId === s.me.buyer;

  const buildMessage = (partial, from, offline) => {
    const msg = { id: uid('m'), from, at: Date.now(), status: offline ? 'pending' : 'sent', ...partial };
    if (msg.type === 'text' && msg.translation == null) {
      msg.lang = langOf(from);
      const t = translate(msg.text, msg.lang);
      msg.translation = t.text;
      msg.exact = t.exact;
    }
    return msg;
  };

  const pushMessage = (n, convId, msg) => {
    const c = n.conversations.find((x) => x.id === convId);
    if (!c) return;
    c.messages.push(msg);
    if (msg.from) c.unread[other(msg.from)] = (c.unread[other(msg.from)] || 0) + 1;
    c.updatedAt = msg.at || Date.now();
  };

  // Programa la respuesta simulada del participante que no es persona de la demo
  const scheduleAuto = (convId, responder, kind) => {
    const run = () => {
      mutate((n) => {
        const c = n.conversations.find((x) => x.id === convId);
        if (c) c.typing = responder;
      });
      setTimeout(() => autoRespond(convId, responder, kind), 2200);
    };
    if (stateRef.current.offline) queuedWhileOffline.current.push(run);
    else setTimeout(run, 900);
  };

  const autoRespond = (convId, responder, kind) => {
    const s = stateRef.current;
    const conv = s.conversations.find((c) => c.id === convId);
    if (!conv) return;
    mutate((n) => {
      const c = n.conversations.find((x) => x.id === convId);
      if (c) c.typing = null;
    });

    if (kind === 'quote') {
      const qm = [...conv.messages].reverse().find((m) => m.type === 'quote' && m.quote.status !== 'superseded');
      if (!qm) return;
      if (qm.quote.status === 'open' && qm.quote.lastBy !== responder) {
        respondQuote(convId, qm.id, 'accept', null, responder);
      } else if (qm.quote.status === 'accepted' && qm.quote.acceptedBy !== responder) {
        respondQuote(convId, qm.id, 'confirm', null, responder);
      }
      return;
    }

    const options = AUTO_REPLIES[responder];
    const r = options[(conv.autoIdx || 0) % options.length];
    const lang = langOf(responder);
    const msg = buildMessage(
      { type: 'text', text: r[lang], translation: r[lang === 'es' ? 'en' : 'es'], lang, exact: true },
      responder,
      false,
    );
    mutate((n) => {
      pushMessage(n, convId, msg);
      const c = n.conversations.find((x) => x.id === convId);
      c.autoIdx = (c.autoIdx || 0) + 1;
    });
  };

  // ── Acciones públicas ─────────────────────────────────────────────
  const setRole = (r) => mutate((n) => { n.role = r; });

  const toggleOffline = () => {
    const s = stateRef.current;
    if (!s.offline) {
      mutate((n) => { n.offline = true; });
      return;
    }
    const pending = countPending(s);
    mutate((n) => {
      n.offline = false;
      n.syncing = pending > 0;
    });
    if (!pending) return;
    setTimeout(() => {
      mutate((n) => {
        n.syncing = false;
        n.conversations.forEach((c) => c.messages.forEach((m) => { if (m.status === 'pending') m.status = 'sent'; }));
        n.agreements.forEach((a) => { if (a.pending) a.pending = false; });
      });
      const l = langOf(stateRef.current.role);
      showToast(l === 'es' ? `${pending} elemento(s) enviados` : `${pending} item(s) synced`, '🔄');
      const queued = queuedWhileOffline.current;
      queuedWhileOffline.current = [];
      queued.forEach((fn) => setTimeout(fn, 600));
    }, 2200);
  };

  const reset = () => {
    queuedWhileOffline.current = [];
    const fresh = createSeed();
    setState(fresh);
  };

  const replayOnboarding = () => mutate((n) => { n.onboarded = false; });

  const completeOnboarding = (r, form = {}) => {
    mutate((n) => {
      n.onboarded = true;
      n.role = r;
      if (r === 'farmer' && form.name) {
        const f = n.farms.find((x) => x.id === n.me.farmer);
        f.producer = form.name;
        if (form.farmName) f.name = form.farmName;
      }
      if (r === 'buyer' && form.name) {
        const b = n.buyers.find((x) => x.id === n.me.buyer);
        b.contact = form.name;
        if (form.company) b.company = form.company;
      }
    });
  };

  const markRead = (convId) => {
    const s = stateRef.current;
    const c = s.conversations.find((x) => x.id === convId);
    if (c && c.unread[s.role] > 0) {
      mutate((n) => {
        const cc = n.conversations.find((x) => x.id === convId);
        cc.unread[n.role] = 0;
      });
    }
  };

  /** Busca o crea la conversación entre una finca y un comprador. Devuelve su id. */
  const startConversation = (farmId, buyerId, { lotId = null, firstMessage = null } = {}) => {
    const s = stateRef.current;
    let conv = s.conversations.find((c) => c.farmId === farmId && c.buyerId === buyerId);
    const convId = conv ? conv.id : uid('c');
    const from = s.role;
    const msg = firstMessage ? buildMessage(firstMessage, from, s.offline) : null;
    mutate((n) => {
      let c = n.conversations.find((x) => x.id === convId);
      if (!c) {
        c = {
          id: convId, farmId, buyerId, lotId, typing: null, autoIdx: 0,
          unread: { farmer: 0, buyer: 0 }, updatedAt: Date.now(),
          messages: [{ id: uid('m'), type: 'system', at: Date.now(), text: { es: 'Conversación iniciada · traducción automática activa', en: 'Conversation started · auto-translation on' } }],
        };
        n.conversations.unshift(c);
      }
      if (lotId) c.lotId = lotId;
      if (msg) pushMessage(n, convId, msg);
    });
    if (msg) {
      const pseudo = conv || { farmId, buyerId };
      if (!isDemoPair(pseudo, s)) scheduleAuto(convId, other(from), 'message');
    }
    return convId;
  };

  const sendMessage = (convId, partial) => {
    const s = stateRef.current;
    const conv = s.conversations.find((c) => c.id === convId);
    if (!conv) return;
    const msg = buildMessage(partial, s.role, s.offline);
    mutate((n) => pushMessage(n, convId, msg));
    if (!isDemoPair(conv, s)) scheduleAuto(convId, other(s.role), 'message');
  };

  const sendQuote = (convId, { lotId, priceLb, sacks, incoterm }) => {
    const s = stateRef.current;
    const conv = s.conversations.find((c) => c.id === convId);
    const at = Date.now();
    const msg = buildMessage(
      {
        type: 'quote',
        quote: {
          lotId, priceLb, sacks, incoterm,
          history: [{ by: s.role, priceLb, sacks, at }],
          lastBy: s.role, status: 'open', acceptedBy: null, agreementId: null,
        },
      },
      s.role,
      s.offline,
    );
    mutate((n) => {
      const c = n.conversations.find((x) => x.id === convId);
      // una cotización nueva reemplaza a las que sigan abiertas
      c.messages.forEach((m) => { if (m.type === 'quote' && ['open', 'accepted'].includes(m.quote.status)) m.quote.status = 'superseded'; });
      c.lotId = lotId;
      pushMessage(n, convId, msg);
    });
    if (conv && !isDemoPair(conv, s)) scheduleAuto(convId, other(s.role), 'quote');
  };

  /**
   * Responde una cotización.
   * action: 'counter' (contraoferta) | 'accept' (acepta la última oferta) | 'confirm' (segunda confirmación → acuerdo)
   */
  const respondQuote = (convId, msgId, action, data = null, asRole = null) => {
    const s = stateRef.current;
    const by = asRole || s.role;
    const conv = s.conversations.find((c) => c.id === convId);
    if (!conv) return;
    const qm = conv.messages.find((m) => m.id === msgId);
    if (!qm) return;
    const offline = s.offline && !asRole;
    const at = Date.now();

    if (action === 'counter') {
      const q = qm.quote;
      const msg = buildMessage(
        {
          type: 'quote',
          quote: {
            ...q,
            priceLb: data.priceLb,
            sacks: data.sacks,
            history: [...q.history, { by, priceLb: data.priceLb, sacks: data.sacks, at }],
            lastBy: by, status: 'open', acceptedBy: null,
          },
        },
        by,
        offline,
      );
      mutate((n) => {
        const c = n.conversations.find((x) => x.id === convId);
        c.messages.find((m) => m.id === msgId).quote.status = 'superseded';
        pushMessage(n, convId, msg);
      });
      if (!isDemoPair(conv, s) && !asRole) scheduleAuto(convId, other(by), 'quote');
      return;
    }

    if (action === 'accept') {
      const sys = {
        id: uid('m'), type: 'system', at, status: offline ? 'pending' : 'sent',
        text: {
          es: `${by === 'farmer' ? 'El caficultor' : 'El comprador'} aceptó US$ ${qm.quote.priceLb.toFixed(2)}/lb · falta la confirmación ${by === 'farmer' ? 'del comprador' : 'del caficultor'}`,
          en: `${by === 'farmer' ? 'The farmer' : 'The buyer'} accepted US$ ${qm.quote.priceLb.toFixed(2)}/lb · waiting for ${by === 'farmer' ? 'the buyer' : 'the farmer'} to confirm`,
        },
      };
      mutate((n) => {
        const c = n.conversations.find((x) => x.id === convId);
        const m = c.messages.find((x) => x.id === msgId);
        m.quote.status = 'accepted';
        m.quote.acceptedBy = by;
        c.messages.push(sys);
        c.unread[other(by)] = (c.unread[other(by)] || 0) + 1;
        c.updatedAt = at;
      });
      if (!isDemoPair(conv, s) && !asRole) scheduleAuto(convId, other(by), 'quote');
      return;
    }

    if (action === 'confirm') {
      const agId = uid('a');
      const code = `CD-2026-${String(102 + s.agreements.length).padStart(4, '0')}`;
      const lot = s.lots.find((l) => l.id === qm.quote.lotId);
      const firstAt = qm.quote.history[0]?.at || at;
      const agreement = {
        id: agId, code, convId,
        farmId: conv.farmId, buyerId: conv.buyerId,
        lotId: qm.quote.lotId, lotName: lot?.name || '', variety: lot?.variety || '', process: lot?.process || '', sca: lot?.sca || 0,
        priceLb: qm.quote.priceLb, sacks: qm.quote.sacks, incoterm: qm.quote.incoterm,
        createdAt: at, status: 1, history: [firstAt, at], ratings: {}, pending: offline,
      };
      const agMsg = { id: uid('m'), type: 'agreement', at, agreementId: agId, status: offline ? 'pending' : 'sent' };
      mutate((n) => {
        const c = n.conversations.find((x) => x.id === convId);
        const m = c.messages.find((x) => x.id === msgId);
        m.quote.status = 'agreed';
        m.quote.agreementId = agId;
        c.messages.push(agMsg);
        c.unread[other(by)] = (c.unread[other(by)] || 0) + 1;
        c.updatedAt = at;
        n.agreements.unshift(agreement);
        const l = n.lots.find((x) => x.id === qm.quote.lotId);
        if (l) l.sacks = Math.max(0, l.sacks - qm.quote.sacks);
      });
      const l = langOf(s.role);
      showToast(l === 'es' ? `Acuerdo ${code} registrado` : `Agreement ${code} registered`, '🤝');
    }
  };

  const advanceAgreement = (agId) => {
    const s = stateRef.current;
    const a = s.agreements.find((x) => x.id === agId);
    if (!a || a.status >= 3) return;
    const next = a.status + 1;
    const sysText = [null, null,
      { es: 'Café despachado 🚢 · en camino', en: 'Coffee shipped 🚢 · on its way' },
      { es: 'Café entregado ✅ · ya pueden calificarse', en: 'Coffee delivered ✅ · you can now rate each other' },
    ][next];
    mutate((n) => {
      const ag = n.agreements.find((x) => x.id === agId);
      ag.status = next;
      ag.history[next] = Date.now();
      if (ag.convId && sysText) {
        const c = n.conversations.find((x) => x.id === ag.convId);
        if (c) {
          c.messages.push({ id: uid('m'), type: 'system', at: Date.now(), text: sysText });
          c.updatedAt = Date.now();
        }
      }
    });
    const l = langOf(s.role);
    if (next === 3) showToast(l === 'es' ? 'Entregado · ya puedes calificar' : 'Delivered · you can rate now', '📦');
  };

  const rateAgreement = (agId, by, { stars, tags, comment }) => {
    const text = comment?.trim() || '';
    const fromLang = langOf(by);
    const translated = text ? translate(text, fromLang).text : '';
    mutate((n) => {
      const ag = n.agreements.find((x) => x.id === agId);
      const key = by === 'farmer' ? 'byFarmer' : 'byBuyer';
      ag.ratings[key] = {
        stars, tags,
        comment: text ? { [fromLang]: text, [fromLang === 'es' ? 'en' : 'es']: translated } : null,
        at: Date.now(),
      };
    });
    showToast(langOf(by) === 'es' ? '¡Gracias por calificar!' : 'Thanks for your rating!', '⭐');
  };

  const publishLot = (data) => {
    const id = uid('l');
    mutate((n) => {
      n.lots.unshift({ id, farmId: n.me.farmer, createdAt: Date.now(), isNew: true, ...data });
    });
    return id;
  };

  const actions = {
    setRole, toggleOffline, reset, replayOnboarding, completeOnboarding, markRead,
    startConversation, sendMessage, sendQuote, respondQuote, advanceAgreement, rateAgreement, publishLot,
    showToast,
  };

  const meFarm = state.farms.find((f) => f.id === state.me.farmer);
  const meBuyer = state.buyers.find((b) => b.id === state.me.buyer);

  const myConversations = useMemo(
    () =>
      state.conversations
        .filter((c) => (role === 'farmer' ? c.farmId === state.me.farmer : c.buyerId === state.me.buyer))
        .sort((a, b) => b.updatedAt - a.updatedAt),
    [state.conversations, role, state.me],
  );
  const unreadTotal = myConversations.reduce((acc, c) => acc + (c.unread[role] || 0), 0);

  const value = {
    state, role, lang, tr, pick, actions, toast, meFarm, meBuyer, myConversations, unreadTotal,
    pendingCount: countPending(state),
  };
  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function countPending(s) {
  let n = 0;
  s.conversations.forEach((c) => c.messages.forEach((m) => { if (m.status === 'pending') n++; }));
  return n;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp debe usarse dentro de <AppProvider>');
  return ctx;
}
