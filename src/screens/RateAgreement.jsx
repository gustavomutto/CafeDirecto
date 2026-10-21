import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import { Avatar, EmptyState, TopBar } from '../components/ui';

export const RATING_TAGS = {
  quality: { es: 'Calidad igual a la muestra', en: 'Matched the sample' },
  communication: { es: 'Buena comunicación', en: 'Great communication' },
  payment: { es: 'Pagó a tiempo', en: 'Paid on time' },
  punctual: { es: 'Cumplió los tiempos', en: 'On time' },
  transparent: { es: 'Transparente', en: 'Transparent' },
  packaging: { es: 'Buen empaque', en: 'Good packaging' },
};

const TAGS_FOR = {
  farmer: ['payment', 'communication', 'transparent', 'punctual'], // el caficultor califica al comprador
  buyer: ['quality', 'communication', 'packaging', 'punctual'], // el comprador califica al caficultor
};

const LABELS = {
  es: ['', 'Malo', 'Regular', 'Bueno', 'Muy bueno', '¡Excelente!'],
  en: ['', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent!'],
};

/** Calificación mutua tras la entrega — RF-20, RF-21 */
export default function RateAgreement() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { state, role, lang, tr, pick, actions } = useApp();
  const [stars, setStars] = useState(0);
  const [tags, setTags] = useState([]);
  const [comment, setComment] = useState('');
  const a = state.agreements.find((x) => x.id === id);
  if (!a) return <div className="screen"><TopBar /><EmptyState title="—" /></div>;

  const farm = state.farms.find((f) => f.id === a.farmId);
  const buyer = state.buyers.find((b) => b.id === a.buyerId);
  const target = role === 'farmer'
    ? { name: buyer.contact, sub: buyer.company, photo: buyer.contactPhoto }
    : { name: farm.producer, sub: farm.name, photo: farm.producerPhoto };

  const submit = () => {
    actions.rateAgreement(a.id, role, { stars, tags, comment });
    navigate(`/orders/${a.id}`, { replace: true });
  };

  return (
    <div className="screen rate">
      <TopBar title={tr('Calificar', 'Rate')} />
      <div className="screen-body center">
        <Avatar src={target.photo} name={target.name} size={88} />
        <h2>{target.name}</h2>
        <p className="muted">{target.sub} · {a.code}</p>

        <p className="rate-q">{tr('¿Cómo te fue con este negocio?', 'How was this deal?')}</p>
        <div className="star-input">
          {[1, 2, 3, 4, 5].map((i) => (
            <button key={i} onClick={() => setStars(i)} className={stars >= i ? 'on' : ''} aria-label={`${i}`}>
              <Icon name="star" size={42} stroke={1.5} fill={stars >= i ? 'currentColor' : 'none'} />
            </button>
          ))}
        </div>
        <b className="star-label">{LABELS[lang][stars] || ' '}</b>

        <div className="chip-wrap center">
          {TAGS_FOR[role].map((t) => (
            <button key={t} className={`chip ${tags.includes(t) ? 'active' : ''}`} onClick={() => setTags(tags.includes(t) ? tags.filter((x) => x !== t) : [...tags, t])}>
              {pick(RATING_TAGS[t])}
            </button>
          ))}
        </div>

        <textarea
          className="textarea"
          rows={3}
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          placeholder={tr('Comentario (opcional)', 'Comment (optional)')}
        />
      </div>
      <div className="screen-footer">
        <button className="btn btn-primary btn-lg btn-block" disabled={!stars} onClick={submit}>
          <Icon name="check" /> {tr('Enviar calificación', 'Submit rating')}
        </button>
      </div>
    </div>
  );
}
