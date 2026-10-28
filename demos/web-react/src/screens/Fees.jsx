import { useState } from 'react';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import { Stepper, TopBar } from '../components/ui';
import { fmtUSD, quoteTotal } from '../utils';

// Modelo de comisiones de la demo (supuesto, ajustable)
export const FEES = { farmer: 0.02, buyer: 0.04 };

/** Comisiones y condiciones claras — RF-27 */
export default function Fees() {
  const { tr, lang } = useApp();
  const [sacks, setSacks] = useState(20);
  const [price, setPrice] = useState(5.6);
  const total = quoteTotal(price, sacks);
  const farmerFee = total * FEES.farmer;
  const buyerFee = total * FEES.buyer;

  const rows = [
    { label: tr('Crear cuenta y perfil', 'Account & profile'), farmer: tr('Gratis', 'Free'), buyer: tr('Gratis', 'Free') },
    { label: tr('Publicar lotes', 'Publish lots'), farmer: tr('Gratis', 'Free'), buyer: '—' },
    { label: tr('Mensajes y traducción', 'Messages & translation'), farmer: tr('Gratis', 'Free'), buyer: tr('Gratis', 'Free') },
    { label: tr('Verificación de comprador', 'Buyer verification'), farmer: '—', buyer: tr('Gratis', 'Free') },
    { label: tr('Acuerdo cerrado', 'Closed agreement'), farmer: '2 %', buyer: '4 %', strong: true },
  ];

  return (
    <div className="screen fees">
      <TopBar title={tr('Comisiones y condiciones', 'Fees & terms')} />
      <div className="screen-body">
        <div className="fees-hero">
          <span>🤝</span>
          <h2>{tr('Solo cobramos cuando usted vende', 'We only charge when a deal closes')}</h2>
          <p>{tr('Sin mensualidades. Sin costos ocultos.', 'No subscriptions. No hidden costs.')}</p>
        </div>

        <table className="fee-table">
          <thead>
            <tr>
              <th></th>
              <th>{tr('Caficultor', 'Farmer')}</th>
              <th>{tr('Comprador', 'Buyer')}</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.label} className={r.strong ? 'strong' : ''}>
                <td>{r.label}</td>
                <td>{r.farmer}</td>
                <td>{r.buyer}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <h3 className="section-title">{tr('Calcule un ejemplo', 'Try an example')}</h3>
        <div className="card">
          <small className="muted">{tr('Sacos de 70 kg', '70 kg bags')}</small>
          <Stepper value={sacks} min={1} max={100} onChange={setSacks} label={tr('sacos', 'bags')} />
          <small className="muted">{tr('Precio por libra', 'Price per pound')}</small>
          <Stepper value={price} min={2} max={20} step={0.1} onChange={setPrice} format={(v) => fmtUSD(v, lang)} label="USD / lb" />
          <dl className="calc">
            <div><dt>{tr('Valor del negocio', 'Deal value')}</dt><dd>{fmtUSD(total, lang, 0)}</dd></div>
            <div><dt>{tr('Comisión caficultor (2 %)', 'Farmer fee (2%)')}</dt><dd>− {fmtUSD(farmerFee, lang, 0)}</dd></div>
            <div className="strong"><dt>{tr('El caficultor recibe', 'Farmer receives')}</dt><dd>{fmtUSD(total - farmerFee, lang, 0)}</dd></div>
            <div><dt>{tr('Comisión comprador (4 %)', 'Buyer fee (4%)')}</dt><dd>+ {fmtUSD(buyerFee, lang, 0)}</dd></div>
          </dl>
        </div>

        <h3 className="section-title">{tr('Condiciones principales', 'Key terms')}</h3>
        <ul className="terms">
          <li><Icon name="check" size={18} /> {tr('El precio lo acuerdan productor y comprador. CaféDirecto no lo fija.', 'Price is agreed between farmer and buyer. CaféDirecto does not set it.')}</li>
          <li><Icon name="check" size={18} /> {tr('El pago y el envío se hacen fuera de la app, con su exportador aliado.', 'Payment and shipping happen outside the app, via the partner exporter.')}</li>
          <li><Icon name="check" size={18} /> {tr('Cada acuerdo queda registrado y visible para ambas partes.', 'Every agreement is recorded and visible to both parties.')}</li>
          <li><Icon name="check" size={18} /> {tr('Solo se califica después de la entrega.', 'Ratings are only possible after delivery.')}</li>
          <li><Icon name="check" size={18} /> {tr('Sus datos y su historia son suyos. Puede borrarlos cuando quiera.', 'Your data and story are yours. Delete them any time.')}</li>
        </ul>
        <p className="fine-print"><Icon name="info" size={13} /> {tr('Valores de ejemplo para la demo.', 'Sample values for the demo.')}</p>
      </div>
    </div>
  );
}
