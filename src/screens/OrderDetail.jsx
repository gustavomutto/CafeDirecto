import { Link, useParams } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import AgreementCard from '../components/AgreementCard';
import Icon from '../components/Icon';
import StatusTimeline from '../components/StatusTimeline';
import { EmptyState, Stars, TopBar } from '../components/ui';
import { STATUS_STEPS } from '../data/catalog';
import { RATING_TAGS } from './RateAgreement';

export default function OrderDetail() {
  const { id } = useParams();
  const { state, role, tr, pick, actions } = useApp();
  const a = state.agreements.find((x) => x.id === id);
  if (!a) return <div className="screen"><TopBar /><EmptyState title={tr('Acuerdo no encontrado', 'Agreement not found')} /></div>;

  const farm = state.farms.find((f) => f.id === a.farmId);
  const buyer = state.buyers.find((b) => b.id === a.buyerId);
  const myKey = role === 'farmer' ? 'byFarmer' : 'byBuyer';
  const theirKey = role === 'farmer' ? 'byBuyer' : 'byFarmer';
  const mine = a.ratings[myKey];
  const theirs = a.ratings[theirKey];
  const otherName = role === 'farmer' ? buyer.contact : farm.producer;
  const next = STATUS_STEPS[a.status + 1];

  const ratingBlock = (r, title) => (
    <div className="rating-given">
      <small>{title}</small>
      <Stars value={r.stars} size={18} />
      {r.tags?.length > 0 && (
        <div className="chip-wrap">
          {r.tags.map((t) => <span key={t} className="note-chip">{pick(RATING_TAGS[t])}</span>)}
        </div>
      )}
      {r.comment && <p>“{pick(r.comment)}”</p>}
    </div>
  );

  return (
    <div className="screen">
      <TopBar title={a.code} subtitle={tr('Detalle del acuerdo', 'Agreement detail')} />
      <div className="screen-body">
        <AgreementCard agreement={a} />

        <h3 className="section-title">{tr('Estado del pedido', 'Order status')}</h3>
        <div className="card">
          <StatusTimeline status={a.status} history={a.history} vertical />
          {a.status < 3 && (
            <button className="btn btn-demo btn-block" onClick={() => actions.advanceAgreement(a.id)}>
              <Icon name="sparkles" size={18} /> {tr('Demo: marcar como', 'Demo: mark as')} “{pick(next)}”
            </button>
          )}
          <p className="fine-print">
            <Icon name="info" size={13} /> {tr('La logística y el pago se gestionan fuera de CaféDirecto.', 'Logistics and payment are handled outside CaféDirecto.')}
          </p>
        </div>

        <h3 className="section-title">{tr('Calificaciones', 'Ratings')}</h3>
        <div className="card">
          {a.status < 3 && (
            <p className="muted">{tr('Podrán calificarse cuando el café sea entregado.', 'You can rate each other once the coffee is delivered.')}</p>
          )}
          {a.status === 3 && !mine && (
            <Link to={`/rate/${a.id}`} className="btn btn-primary btn-lg btn-block">
              <Icon name="star" /> {tr(`Calificar a ${otherName}`, `Rate ${otherName}`)}
            </Link>
          )}
          {mine && ratingBlock(mine, tr('Tu calificación', 'Your rating'))}
          {theirs
            ? ratingBlock(theirs, tr(`${otherName} te calificó`, `${otherName} rated you`))
            : a.status === 3 && <p className="muted small">{tr(`Esperando la calificación de ${otherName}.`, `Waiting for ${otherName}'s rating.`)}</p>}
        </div>

        {a.convId && (
          <Link to={`/chat/${a.convId}`} className="btn btn-outline btn-block">
            <Icon name="chat" size={18} /> {tr('Abrir conversación', 'Open conversation')}
          </Link>
        )}
      </div>
    </div>
  );
}
