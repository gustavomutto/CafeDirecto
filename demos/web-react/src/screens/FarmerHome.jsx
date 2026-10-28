import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import LotCard from '../components/LotCard';
import { Avatar, Stars } from '../components/ui';
import { LEARN } from '../data/learn';
import { farmRating, firstName } from '../utils';

/** Inicio del caficultor: botones grandes y pocas palabras */
export default function FarmerHome() {
  const { state, meFarm, unreadTotal } = useApp();
  const myLots = state.lots.filter((l) => l.farmId === meFarm.id);
  const rating = farmRating(meFarm, state.agreements);
  const activeDeals = state.agreements.filter((a) => a.farmId === meFarm.id && a.status < 3).length;
  const tip = LEARN[new Date().getDate() % LEARN.length];

  const tiles = [
    { to: '/publish', icon: 'plus', label: 'Publicar lote', cls: 'primary' },
    { to: '/chats', icon: 'chat', label: 'Mensajes', badge: unreadTotal },
    { to: '/orders', icon: 'handshake', label: 'Mis acuerdos', badge: activeDeals, badgeCls: 'green' },
    { to: '/learn', icon: 'book', label: 'Aprende' },
  ];

  return (
    <div className="screen farmer-home">
      <div className="screen-body">
        <header className="home-hero">
          <Avatar src={meFarm.producerPhoto} name={meFarm.producer} size={58} />
          <div>
            <h1>Hola, {firstName(meFarm.producer)} 👋</h1>
            <p>{meFarm.name} · {meFarm.region}</p>
            <Stars value={rating.avg} size={15} showValue count={rating.count} />
          </div>
        </header>

        <div className="big-actions">
          {tiles.map((t) => (
            <Link key={t.to} to={t.to} className={`big-action ${t.cls || ''}`}>
              <span className="ba-icon">
                <Icon name={t.icon} size={34} stroke={2.2} />
                {t.badge > 0 && <span className={`badge big ${t.badgeCls || ''}`}>{t.badge}</span>}
              </span>
              <b>{t.label}</b>
            </Link>
          ))}
        </div>

        {unreadTotal > 0 && (
          <Link to="/chats" className="alert-card">
            <span className="alert-emoji">💬</span>
            <span>
              <b>Tienes {unreadTotal} mensaje{unreadTotal > 1 ? 's' : ''} nuevo{unreadTotal > 1 ? 's' : ''}</b>
              <small>Un comprador espera tu respuesta</small>
            </span>
            <Icon name="chevron" />
          </Link>
        )}

        <h3 className="section-title">Mis lotes publicados</h3>
        <div className="lot-rows">
          {myLots.map((l) => <LotCard key={l.id} lot={l} compact />)}
        </div>

        <Link to={`/learn/${tip.id}`} className="tip-card" style={{ background: tip.color }}>
          <span className="tip-emoji">{tip.icon}</span>
          <span>
            <small>Consejo del día</small>
            <b>{tip.title.es}</b>
            <span>{tip.summary.es}</span>
          </span>
        </Link>
      </div>
    </div>
  );
}
