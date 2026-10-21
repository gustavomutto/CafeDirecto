import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { INCOTERMS, PROCESSES } from '../data/catalog';
import { fmtDate, fmtNum, fmtUSD, quoteTotal, KG_PER_SACK } from '../utils';
import Icon from './Icon';
import StatusTimeline from './StatusTimeline';

/** Tarjeta "Acuerdo registrado": visible para ambas partes en el chat y en Pedidos */
export default function AgreementCard({ agreement: a, inChat = false }) {
  const { state, tr, pick, lang } = useApp();
  const farm = state.farms.find((f) => f.id === a.farmId);
  const buyer = state.buyers.find((b) => b.id === a.buyerId);
  const total = quoteTotal(a.priceLb, a.sacks);

  return (
    <div className={`agreement-card ${inChat ? 'in-chat' : ''}`}>
      <div className="ag-head">
        <span className="ag-seal">🤝</span>
        <div>
          <b>{tr('Acuerdo registrado', 'Agreement registered')}</b>
          <small>{a.code} · {fmtDate(a.createdAt, lang)}</small>
        </div>
        {a.pending && <span className="pending-chip"><Icon name="clock" size={12} /> {tr('Pendiente', 'Pending')}</span>}
      </div>

      <div className="ag-parties">
        <div>
          <small>{tr('Productor', 'Producer')}</small>
          <b>{farm.producer}</b>
          <span>{farm.name} · {farm.region}</span>
        </div>
        <Icon name="handshake" size={20} />
        <div>
          <small>{tr('Comprador', 'Buyer')}</small>
          <b>{buyer.company}</b>
          <span>{buyer.flag} {lang === 'es' ? buyer.city : buyer.cityEn}</span>
        </div>
      </div>

      <dl className="ag-terms">
        <div><dt>{tr('Lote', 'Lot')}</dt><dd>{a.lotName} · {a.variety} {pick(PROCESSES[a.process])}</dd></div>
        <div><dt>{tr('Cantidad', 'Quantity')}</dt><dd>{a.sacks} {tr('sacos', 'bags')} × {KG_PER_SACK} kg = {fmtNum(a.sacks * KG_PER_SACK, lang)} kg</dd></div>
        <div><dt>{tr('Precio', 'Price')}</dt><dd>{fmtUSD(a.priceLb, lang)} / lb</dd></div>
        <div><dt>{tr('Condición', 'Terms')}</dt><dd>{pick(INCOTERMS[a.incoterm]) || a.incoterm}</dd></div>
        <div className="ag-total"><dt>{tr('Valor total', 'Total value')}</dt><dd>{fmtUSD(total, lang, 0)}</dd></div>
      </dl>

      <StatusTimeline status={a.status} history={a.history} />

      {inChat && (
        <Link to={`/orders/${a.id}`} className="btn btn-ghost btn-sm">
          {tr('Ver acuerdo', 'View agreement')} <Icon name="chevron" size={16} />
        </Link>
      )}
    </div>
  );
}
