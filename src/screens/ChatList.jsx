import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import { Avatar, EmptyState } from '../components/ui';
import { fmtTime, fmtUSD } from '../utils';

/** Texto corto del último mensaje, en el idioma de quien mira */
export function usePreview() {
  const { lang, tr, pick } = useApp();
  return (m) => {
    if (!m) return '';
    switch (m.type) {
      case 'text': return m.lang === lang ? m.text : m.translation;
      case 'voice': return `🎙️ ${tr('Nota de voz', 'Voice note')}`;
      case 'photo': return `📷 ${tr('Foto', 'Photo')}`;
      case 'quote': return `💲 ${tr('Cotización', 'Quote')}: ${fmtUSD(m.quote.priceLb, lang)}/lb`;
      case 'agreement': return `🤝 ${tr('Acuerdo registrado', 'Agreement registered')}`;
      case 'system': return pick(m.text);
      default: return '';
    }
  };
}

export default function ChatList() {
  const { state, role, tr, myConversations } = useApp();
  const preview = usePreview();

  return (
    <div className="screen">
      <div className="screen-body">
        <header className="page-head">
          <h1>{tr('Mensajes', 'Messages')}</h1>
          <p className="muted"><Icon name="translate" size={15} /> {tr('Todo se traduce automáticamente', 'Everything is translated automatically')}</p>
        </header>

        {myConversations.length === 0 && (
          <EmptyState icon="💬" title={tr('Aún no tienes mensajes', 'No conversations yet')} text={tr('Cuando un comprador te escriba, aparecerá aquí.', 'Contact a farm from Explore to start.')} />
        )}

        <ul className="chat-list">
          {myConversations.map((c) => {
            const farm = state.farms.find((f) => f.id === c.farmId);
            const buyer = state.buyers.find((b) => b.id === c.buyerId);
            const last = [...c.messages].reverse().find((m) => m.type !== 'system') || c.messages[c.messages.length - 1];
            const unread = c.unread[role] || 0;
            const pending = c.messages.some((m) => m.status === 'pending');
            const title = role === 'farmer' ? buyer.contact : farm.producer;
            const sub = role === 'farmer' ? `${buyer.flag} ${buyer.company}` : `${farm.name} · ${farm.region}`;
            const photo = role === 'farmer' ? buyer.contactPhoto : farm.producerPhoto;
            return (
              <li key={c.id}>
                <Link to={`/chat/${c.id}`} className={`chat-row ${unread ? 'unread' : ''}`}>
                  <Avatar src={photo} name={title} size={role === 'farmer' ? 56 : 50} />
                  <span className="chat-row-body">
                    <span className="chat-row-top">
                      <b>{title}</b>
                      <small>{fmtTime(c.updatedAt, role === 'farmer' ? 'es' : 'en')}</small>
                    </span>
                    <small className="chat-row-sub">{sub}</small>
                    <span className="chat-row-last">
                      {c.typing && c.typing !== role ? <em>{tr('escribiendo…', 'typing…')}</em> : preview(last)}
                    </span>
                  </span>
                  {pending && <Icon name="clock" size={16} className="muted" />}
                  {unread > 0 && <span className="badge big">{unread}</span>}
                </Link>
              </li>
            );
          })}
        </ul>
      </div>
    </div>
  );
}
