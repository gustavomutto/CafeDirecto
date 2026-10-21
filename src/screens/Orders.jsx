import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import StatusTimeline from '../components/StatusTimeline';
import { Avatar, EmptyState } from '../components/ui';
import { STATUS_STEPS } from '../data/catalog';
import { fmtDate, fmtUSD, quoteTotal } from '../utils';

/** Mis pedidos / acuerdos — RF-18 */
export default function Orders() {
  const { state, role, tr, pick, lang } = useApp();
  const mine = state.agreements
    .filter((a) => (role === 'farmer' ? a.farmId === state.me.farmer : a.buyerId === state.me.buyer))
    .sort((a, b) => b.createdAt - a.createdAt);
  const active = mine.filter((a) => a.status < 3);
  const done = mine.filter((a) => a.status >= 3);

  const totalValue = mine.reduce((s, a) => s + quoteTotal(a.priceLb, a.sacks), 0);

  const card = (a) => {
    const farm = state.farms.find((f) => f.id === a.farmId);
    const buyer = state.buyers.find((b) => b.id === a.buyerId);
    const name = role === 'farmer' ? buyer.company : farm.name;
    const photo = role === 'farmer' ? buyer.contactPhoto : farm.producerPhoto;
    const myKey = role === 'farmer' ? 'byFarmer' : 'byBuyer';
    const needsRating = a.status === 3 && !a.ratings[myKey];
    return (
      <Link key={a.id} to={`/orders/${a.id}`} className="order-card">
        <div className="order-top">
          <Avatar src={photo} name={name} size={44} />
          <span className="order-title">
            <b>{name}</b>
            <small>{a.code} · {fmtDate(a.createdAt, lang)}</small>
          </span>
          <span className={`status-pill s${a.status}`}>{pick(STATUS_STEPS[a.status])}</span>
        </div>
        <div className="order-mid">
          <span>{a.lotName} · {a.sacks} × 70 kg</span>
          <b>{fmtUSD(quoteTotal(a.priceLb, a.sacks), lang, 0)}</b>
        </div>
        <StatusTimeline status={a.status} />
        {needsRating && (
          <span className="rate-cta"><Icon name="star" size={16} /> {tr('Califica este negocio', 'Rate this deal')}</span>
        )}
      </Link>
    );
  };

  return (
    <div className="screen">
      <div className="screen-body">
        <header className="page-head">
          <h1>{tr('Mis acuerdos', 'Orders & agreements')}</h1>
          <p className="muted">
            {mine.length} {tr('acuerdos', 'agreements')} · {fmtUSD(totalValue, lang, 0)} {tr('en total', 'total')}
          </p>
        </header>

        {mine.length === 0 && (
          <EmptyState icon="🤝" title={tr('Todavía no tienes acuerdos', 'No agreements yet')} text={tr('Cuando confirmes un precio en el chat, aparecerá aquí.', 'Confirmed quotes from chat will appear here.')} />
        )}

        {active.length > 0 && <h3 className="section-title">{tr('En curso', 'In progress')}</h3>}
        <div className="order-list">{active.map(card)}</div>

        {done.length > 0 && <h3 className="section-title">{tr('Entregados', 'Delivered')}</h3>}
        <div className="order-list">{done.map(card)}</div>
      </div>
    </div>
  );
}
