import { Link, useNavigate, useParams } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import { Avatar, EmptyState, Img, ScoreBadge, Stars, TopBar } from '../components/ui';
import { NOTES, PROCESSES } from '../data/catalog';
import { TEMPLATES } from '../data/phrases';
import { farmRating, fmtNum, fmtUSD } from '../utils';

/** Detalle del lote enlazado a la finca, con certificaciones solo visibles — RF-08, RF-23 */
export default function LotDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { state, role, tr, pick, lang, actions } = useApp();
  const lot = state.lots.find((l) => l.id === id);
  if (!lot) return <div className="screen"><TopBar /><EmptyState title={tr('Lote no encontrado', 'Lot not found')} /></div>;
  const farm = state.farms.find((f) => f.id === lot.farmId);
  const rating = farmRating(farm, state.agreements);
  const proc = PROCESSES[lot.process];
  const isOwn = role === 'farmer' && farm.id === state.me.farmer;

  const contact = (withSample) => {
    const tpl = TEMPLATES.buyer.find((t) => t.id === 'b2');
    const cid = actions.startConversation(farm.id, state.me.buyer, {
      lotId: lot.id,
      firstMessage: withSample ? { type: 'text', text: tpl.en, translation: tpl.es, lang: 'en', exact: true, lotRef: lot.id } : null,
    });
    navigate(`/chat/${cid}`);
  };

  const specs = [
    { icon: 'bean', label: tr('Variedad', 'Variety'), value: lot.variety },
    { icon: 'leaf', label: tr('Proceso', 'Process'), value: `${proc.icon} ${pick(proc)}` },
    { icon: 'mountain', label: tr('Altitud', 'Altitude'), value: `${fmtNum(farm.altitude, lang)} m` },
    { icon: 'receipt', label: tr('Disponible', 'Available'), value: `${lot.sacks} × 70 kg` },
    { icon: 'clock', label: tr('Cosecha', 'Harvest'), value: pick(lot.harvest) },
    { icon: 'pin', label: tr('Origen', 'Origin'), value: `${farm.municipality}, ${farm.region}` },
  ];

  return (
    <div className="screen lot-detail">
      <div className="screen-body no-pad">
        <div className="hero">
          <Img src={lot.photo} alt={lot.name} />
          <div className="hero-shade" />
          <TopBar transparent />
          <div className="hero-text">
            <span className="eyebrow light">{farm.region} · Colombia</span>
            <h1>{lot.name}</h1>
            <p>{lot.variety} · {pick(proc)}</p>
          </div>
          <ScoreBadge sca={lot.sca} large />
        </div>

        <div className="pad">
          <div className="price-strip">
            <div>
              <small>{tr('Precio de referencia', 'Reference price')}</small>
              <b>{fmtUSD(lot.priceLb, lang)}<span> / lb</span></b>
            </div>
            <div className="right">
              <small>{tr('Negociable en el chat', 'Negotiable in chat')}</small>
              <span className="pill green">FOB</span>
            </div>
          </div>

          <Link to={`/farm/${farm.id}`} className="farm-link">
            <Avatar src={farm.producerPhoto} name={farm.producer} size={52} />
            <span>
              <b>{farm.name}</b>
              <small>{farm.producer} · {farm.hectares} ha</small>
              <Stars value={rating.avg} size={12} showValue count={rating.count} />
            </span>
            <span className="link-cta">{tr('Ver finca', 'Farm story')} <Icon name="chevron" size={16} /></span>
          </Link>

          <div className="spec-grid">
            {specs.map((s) => (
              <div key={s.label} className="spec">
                <Icon name={s.icon} size={18} />
                <small>{s.label}</small>
                <b>{s.value}</b>
              </div>
            ))}
          </div>

          <h3 className="section-title">{tr('Notas de catación', 'Cupping notes')}</h3>
          <div className="chip-wrap">
            {lot.notes.map((n) => <span key={n} className="note-chip">{pick(NOTES[n])}</span>)}
          </div>

          <h3 className="section-title">{tr('Certificaciones de origen', 'Origin certifications')}</h3>
          <div className="cert-list">
            {farm.certifications.map((c) => (
              <div key={c.name} className="cert">
                <Icon name="shield" size={20} />
                <span>
                  <b>{c.name}</b>
                  <small>{c.issuer} · {tr('vigente hasta', 'valid until')} {c.valid}</small>
                </span>
                <Icon name="lock" size={16} className="muted" />
              </div>
            ))}
            <p className="fine-print">
              <Icon name="info" size={13} /> {tr('Solo visualización. CaféDirecto no emite ni gestiona certificaciones.', 'View only. CaféDirecto does not issue or manage certifications.')}
            </p>
          </div>
        </div>
      </div>

      <div className="screen-footer">
        {role === 'buyer' && (
          <>
            <button className="btn btn-outline" onClick={() => contact(true)}>
              <Icon name="receipt" size={18} /> Request sample
            </button>
            <button className="btn btn-primary btn-block" onClick={() => contact(false)}>
              <Icon name="chat" size={18} /> Message {farm.producer.split(' ')[0]}
            </button>
          </>
        )}
        {isOwn && (
          <div className="own-note">
            <Icon name="eye" size={18} /> {tr('Este es tu lote. Así lo ven los compradores.', 'This is your lot.')}
          </div>
        )}
      </div>
    </div>
  );
}
