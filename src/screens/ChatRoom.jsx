import { useEffect, useRef, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import MessageBubble from '../components/MessageBubble';
import { Avatar, EmptyState, Img, Sheet, Stepper, TopBar, Verified } from '../components/ui';
import { INCOTERMS, PROCESSES } from '../data/catalog';
import { SHAREABLE_PHOTOS, PHOTOS } from '../data/photos';
import { TEMPLATES, VOICE_NOTES } from '../data/phrases';
import { fmtDuration, fmtUSD, quoteTotal } from '../utils';

/** Mensajería directa con traducción, voz, fotos, plantillas y cotización — RF-09 a RF-17 */
export default function ChatRoom() {
  const { id } = useParams();
  const { state, role, lang, tr, pick, actions } = useApp();
  const conv = state.conversations.find((c) => c.id === id);
  const listRef = useRef(null);

  const [text, setText] = useState('');
  const [sheet, setSheet] = useState(null); // 'templates' | 'photos' | 'quote' | 'counter'
  const [counterMsg, setCounterMsg] = useState(null);
  const [counter, setCounter] = useState({ priceLb: 0, sacks: 0 });
  const [quote, setQuote] = useState(null);
  const [recording, setRecording] = useState(null);
  const [recSecs, setRecSecs] = useState(0);

  const msgCount = conv?.messages.length || 0;

  // Marca como leído y baja al último mensaje
  useEffect(() => {
    if (!conv) return;
    actions.markRead(conv.id);
    const el = listRef.current;
    if (el) requestAnimationFrame(() => el.scrollTo({ top: el.scrollHeight, behavior: 'smooth' }));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, msgCount, role, conv?.typing]);

  // Cronómetro de la grabación
  useEffect(() => {
    if (!recording) return;
    const t = setInterval(() => setRecSecs((Date.now() - recording) / 1000), 200);
    return () => clearInterval(t);
  }, [recording]);

  if (!conv) {
    return (
      <div className="screen">
        <TopBar title={tr('Chat', 'Chat')} />
        <EmptyState title={tr('Conversación no encontrada', 'Conversation not found')} />
      </div>
    );
  }

  const farm = state.farms.find((f) => f.id === conv.farmId);
  const buyer = state.buyers.find((b) => b.id === conv.buyerId);
  const lot = state.lots.find((l) => l.id === conv.lotId);
  const myLots = state.lots.filter((l) => l.farmId === farm.id && l.sacks > 0);
  const isFarmer = role === 'farmer';

  const sendText = () => {
    const t = text.trim();
    if (!t) return;
    actions.sendMessage(conv.id, { type: 'text', text: t });
    setText('');
  };

  const sendTemplate = (tpl) => {
    actions.sendMessage(conv.id, { type: 'text', text: tpl[lang], translation: tpl[lang === 'es' ? 'en' : 'es'], lang, exact: true });
    setSheet(null);
  };

  const sendPhoto = (p) => {
    actions.sendMessage(conv.id, { type: 'photo', src: p.src, caption: p.caption });
    setSheet(null);
  };

  const startRecording = () => {
    setRecSecs(0);
    setRecording(Date.now());
  };

  const stopRecording = (send) => {
    const secs = Math.max(3, Math.round((Date.now() - recording) / 1000));
    setRecording(null);
    if (!send) return;
    const used = conv.messages.filter((m) => m.type === 'voice' && m.from === 'farmer').length;
    const note = VOICE_NOTES[used % VOICE_NOTES.length];
    actions.sendMessage(conv.id, { type: 'voice', duration: secs, text: note.es, translation: note.en, lang: 'es' });
  };

  const openQuote = () => {
    const l = lot && lot.farmId === farm.id && lot.sacks > 0 ? lot : myLots[0];
    if (!l) return;
    setQuote({ lotId: l.id, priceLb: l.priceLb, sacks: Math.min(l.sacks, 20), incoterm: 'FOB Buenaventura' });
    setSheet('quote');
  };

  const handlers = {
    onAccept: (m) => actions.respondQuote(conv.id, m.id, 'accept'),
    onConfirm: (m) => actions.respondQuote(conv.id, m.id, 'confirm'),
    onCounter: (m) => {
      setCounterMsg(m);
      const delta = isFarmer ? 0.2 : -0.25;
      setCounter({ priceLb: Math.round((m.quote.priceLb + delta) * 100) / 100, sacks: m.quote.sacks });
      setSheet('counter');
    },
  };

  const other = isFarmer
    ? { name: buyer.contact, sub: `${buyer.flag} ${buyer.company}`, photo: buyer.contactPhoto, to: `/buyer/${buyer.id}`, verified: buyer.verified }
    : { name: farm.producer, sub: `${farm.name} · ${farm.region}`, photo: farm.producerPhoto, to: `/farm/${farm.id}` };

  const quickTemplates = TEMPLATES[role].slice(0, 4);

  return (
    <div className={`screen chat-room ${isFarmer ? 'farmer' : 'buyer'}`}>
      <TopBar
        right={
          <Link to={other.to} className="icon-btn" aria-label={tr('Ver perfil', 'View profile')}>
            <Icon name="info" />
          </Link>
        }
      >
        <Link to={other.to} className="chat-head">
          <Avatar src={other.photo} name={other.name} size={40} />
          <span>
            <b>{other.name} {other.verified && <Verified />}</b>
            <small>{conv.typing && conv.typing !== role ? tr('escribiendo…', 'typing…') : other.sub}</small>
          </span>
        </Link>
      </TopBar>

      <div className="chat-banner">
        <Icon name="translate" size={15} />
        <span>{tr('Traducción automática ES ⇄ EN', 'Auto-translation EN ⇄ ES')}</span>
        {lot && (
          <Link to={`/lot/${lot.id}`} className="chat-lot-chip">
            <Img src={lot.photo} alt="" /> {lot.name}
          </Link>
        )}
      </div>

      <div className="chat-messages" ref={listRef}>
        {conv.messages.map((m) => <MessageBubble key={m.id} msg={m} handlers={handlers} />)}
        {conv.typing && conv.typing !== role && (
          <div className="msg theirs">
            <div className="bubble typing"><i /><i /><i /></div>
          </div>
        )}
      </div>

      {/* Acciones rápidas siempre visibles */}
      <div className="quick-bar">
        {isFarmer ? (
          <>
            <button className="quick-btn price" onClick={openQuote} disabled={!myLots.length}>
              <Icon name="dollar" size={20} /> Enviar precio
            </button>
            <button className="quick-btn" onClick={() => setSheet('templates')}>
              <Icon name="template" size={20} /> Frases
            </button>
            <button className="quick-btn" onClick={() => setSheet('photos')}>
              <Icon name="camera" size={20} /> Foto
            </button>
          </>
        ) : (
          <div className="chip-scroll tight">
            {quickTemplates.map((t) => (
              <button key={t.id} className="chip" onClick={() => sendTemplate(t)}>{t.icon} {t.en}</button>
            ))}
          </div>
        )}
      </div>

      <div className="composer">
        {!isFarmer && (
          <>
            <button className="icon-btn" onClick={() => setSheet('photos')} aria-label="Photo"><Icon name="image" /></button>
            <button className="icon-btn" onClick={() => setSheet('templates')} aria-label="Templates"><Icon name="template" /></button>
          </>
        )}
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && sendText()}
          placeholder={tr('Escribe un mensaje…', 'Write a message…')}
          aria-label={tr('Mensaje', 'Message')}
        />
        {isFarmer && !text.trim() ? (
          <button className="mic-btn" onClick={startRecording} aria-label="Grabar nota de voz">
            <Icon name="mic" size={26} />
          </button>
        ) : (
          <button className="send-btn" onClick={sendText} disabled={!text.trim()} aria-label={tr('Enviar', 'Send')}>
            <Icon name="send" size={20} />
          </button>
        )}
      </div>

      {/* Grabación de voz simulada */}
      {recording && (
        <div className="rec-overlay">
          <div className="rec-card">
            <div className="rec-pulse"><Icon name="mic" size={40} /></div>
            <b className="rec-time">{fmtDuration(recSecs)}</b>
            <div className="rec-wave">{Array.from({ length: 24 }).map((_, i) => <i key={i} style={{ animationDelay: `${i * 60}ms` }} />)}</div>
            <p>Grabando… habla con tranquilidad</p>
            <div className="rec-actions">
              <button className="btn btn-ghost btn-lg" onClick={() => stopRecording(false)}><Icon name="x" /> Cancelar</button>
              <button className="btn btn-primary btn-lg" onClick={() => stopRecording(true)}><Icon name="send" /> Enviar</button>
            </div>
          </div>
        </div>
      )}

      <Sheet open={sheet === 'templates'} onClose={() => setSheet(null)} title={tr('Frases listas', 'Quick messages')}>
        <p className="muted small">{tr('Se envían ya traducidas al inglés.', 'They arrive already translated into Spanish.')}</p>
        <div className="template-list">
          {TEMPLATES[role].map((t) => (
            <button key={t.id} className="template" onClick={() => sendTemplate(t)}>
              <span className="tpl-icon">{t.icon}</span>
              <span>
                <b>{t[lang]}</b>
                <small>{t[lang === 'es' ? 'en' : 'es']}</small>
              </span>
            </button>
          ))}
        </div>
      </Sheet>

      <Sheet open={sheet === 'photos'} onClose={() => setSheet(null)} title={tr('Enviar foto', 'Send photo')}>
        <p className="muted small">{tr('Demo: elige una foto de ejemplo.', 'Demo: pick a sample photo.')}</p>
        <div className="photo-grid">
          {(isFarmer ? SHAREABLE_PHOTOS : [{ src: PHOTOS.shop2, caption: { en: 'Our roastery in Berlin', es: 'Nuestra tostaduría en Berlín' } }, { src: PHOTOS.cup3, caption: { en: 'How we serve your coffee', es: 'Así servimos su café' } }]).map((p) => (
            <button key={p.src} onClick={() => sendPhoto(p)}>
              <Img src={p.src} alt="" />
              <span>{pick(p.caption)}</span>
            </button>
          ))}
        </div>
      </Sheet>

      {quote && (
        <Sheet
          open={sheet === 'quote'}
          onClose={() => setSheet(null)}
          title="Enviar precio"
          footer={
            <button
              className="btn btn-primary btn-lg btn-block"
              onClick={() => { actions.sendQuote(conv.id, quote); setSheet(null); }}
            >
              <Icon name="send" /> Enviar cotización
            </button>
          }
        >
          <h4 className="filter-title">1. ¿Qué lote?</h4>
          <div className="lot-pick">
            {myLots.map((l) => (
              <button
                key={l.id}
                className={quote.lotId === l.id ? 'active' : ''}
                onClick={() => setQuote({ ...quote, lotId: l.id, priceLb: l.priceLb, sacks: Math.min(l.sacks, quote.sacks) })}
              >
                <Img src={l.photo} alt="" />
                <span><b>{l.name}</b><small>{l.variety} · {pick(PROCESSES[l.process])} · {l.sacks} sacos</small></span>
              </button>
            ))}
          </div>
          <h4 className="filter-title">2. Precio por libra (USD)</h4>
          <Stepper value={quote.priceLb} step={0.05} min={1} max={40} onChange={(v) => setQuote({ ...quote, priceLb: v })} format={(v) => fmtUSD(v, 'es')} label="por libra" />
          <h4 className="filter-title">3. ¿Cuántos sacos de 70 kg?</h4>
          <Stepper
            value={quote.sacks}
            min={1}
            max={state.lots.find((l) => l.id === quote.lotId)?.sacks || 1}
            onChange={(v) => setQuote({ ...quote, sacks: v })}
            label="sacos"
          />
          <h4 className="filter-title">4. ¿Dónde se entrega?</h4>
          <div className="chip-wrap">
            {Object.keys(INCOTERMS).map((k) => (
              <button key={k} className={`chip ${quote.incoterm === k ? 'active' : ''}`} onClick={() => setQuote({ ...quote, incoterm: k })}>
                {INCOTERMS[k].es}
              </button>
            ))}
          </div>
          <div className="total-box">
            <span>Total del negocio</span>
            <b>{fmtUSD(quoteTotal(quote.priceLb, quote.sacks), 'es', 0)}</b>
          </div>
        </Sheet>
      )}

      {counterMsg && (
        <Sheet
          open={sheet === 'counter'}
          onClose={() => setSheet(null)}
          title={tr('Contraoferta', 'Counter-offer')}
          footer={
            <button
              className="btn btn-primary btn-lg btn-block"
              onClick={() => { actions.respondQuote(conv.id, counterMsg.id, 'counter', counter); setSheet(null); }}
            >
              <Icon name="send" /> {tr('Enviar contraoferta', 'Send counter-offer')}
            </button>
          }
        >
          <p className="muted small">
            {tr('Oferta actual', 'Current offer')}: <b>{fmtUSD(counterMsg.quote.priceLb, lang)}/lb</b> · {counterMsg.quote.sacks} {tr('sacos', 'bags')}
          </p>
          <h4 className="filter-title">{tr('Tu precio por libra', 'Your price per pound')}</h4>
          <Stepper value={counter.priceLb} step={0.05} min={1} max={40} onChange={(v) => setCounter({ ...counter, priceLb: v })} format={(v) => fmtUSD(v, lang)} label="USD / lb" />
          <h4 className="filter-title">{tr('Sacos de 70 kg', '70 kg bags')}</h4>
          <Stepper value={counter.sacks} min={1} max={60} onChange={(v) => setCounter({ ...counter, sacks: v })} label={tr('sacos', 'bags')} />
          <div className="total-box">
            <span>{tr('Total', 'Total')}</span>
            <b>{fmtUSD(quoteTotal(counter.priceLb, counter.sacks), lang, 0)}</b>
          </div>
        </Sheet>
      )}
    </div>
  );
}
