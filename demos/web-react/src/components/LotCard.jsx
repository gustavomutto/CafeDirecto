import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { PROCESSES } from '../data/catalog';
import { farmRating, fmtNum, fmtUSD } from '../utils';
import Icon from './Icon';
import { Img, ScoreBadge, Stars } from './ui';

export default function LotCard({ lot, compact = false }) {
  const { state, tr, pick, lang } = useApp();
  const farm = state.farms.find((f) => f.id === lot.farmId);
  const rating = farmRating(farm, state.agreements);
  const proc = PROCESSES[lot.process];

  if (compact) {
    return (
      <Link to={`/lot/${lot.id}`} className="lot-row">
        <Img src={lot.photo} alt={lot.name} className="lot-row-img" />
        <div className="lot-row-body">
          <b>{lot.name}</b>
          <span>{lot.variety} · {pick(proc)}</span>
          <span className="muted">
            {lot.sacks} {tr('sacos', 'bags')} · {fmtUSD(lot.priceLb, lang)}/lb
          </span>
        </div>
        <ScoreBadge sca={lot.sca} />
      </Link>
    );
  }

  return (
    <Link to={`/lot/${lot.id}`} className="lot-card">
      <div className="lot-card-media">
        <Img src={lot.photo} alt={lot.name} />
        <ScoreBadge sca={lot.sca} />
        {lot.isNew && <span className="new-badge">{tr('NUEVO', 'NEW')}</span>}
        <span className="lot-region"><Icon name="pin" size={13} /> {farm.region}</span>
      </div>
      <div className="lot-card-body">
        <div className="lot-card-top">
          <div>
            <h3>{farm.name}</h3>
            <p className="muted">{farm.producer} · {farm.municipality}</p>
          </div>
          <div className="lot-price">
            <b>{fmtUSD(lot.priceLb, lang)}</b>
            <small>/lb FOB</small>
          </div>
        </div>
        <div className="lot-meta">
          <span>{lot.variety}</span>
          <span>{proc.icon} {pick(proc)}</span>
          <span><Icon name="mountain" size={13} /> {fmtNum(farm.altitude, lang)} m</span>
        </div>
        <div className="lot-card-foot">
          <Stars value={rating.avg} size={13} showValue count={rating.count} />
          <span className="muted">{lot.sacks} × 70 kg</span>
        </div>
      </div>
    </Link>
  );
}
