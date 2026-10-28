import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import { Img, Segmented, Stepper, TopBar } from '../components/ui';
import { NOTES, PROCESSES, VARIETIES } from '../data/catalog';
import { SHAREABLE_PHOTOS } from '../data/photos';
import { copCargaToUsdLb, fmtCOP, fmtUSD, quoteTotal } from '../utils';

const NOTE_OPTIONS = ['panela', 'chocolate', 'caramelo', 'frutosrojos', 'citrico', 'floral', 'miel', 'mandarina'];

/** Publicar lote (caficultor) — RF-06. Formulario de pasos grandes y numerados. */
export default function PublishLot() {
  const { actions } = useApp();
  const navigate = useNavigate();
  const [f, setF] = useState({
    variety: 'Pink Bourbon',
    process: 'honey',
    sacks: 10,
    sca: 86,
    unit: 'lb',
    priceLb: 5.5,
    priceCarga: 3200000,
    notes: ['panela', 'chocolate'],
    photo: 0,
    name: '',
  });
  const [doneId, setDoneId] = useState(null);
  const set = (k, v) => setF({ ...f, [k]: v });
  const priceLb = f.unit === 'lb' ? f.priceLb : Math.round(copCargaToUsdLb(f.priceCarga) * 100) / 100;

  const publish = () => {
    const id = actions.publishLot({
      name: f.name.trim() || `Lote ${f.variety}`,
      variety: f.variety,
      process: f.process,
      sacks: f.sacks,
      sca: f.sca,
      priceLb,
      priceUnit: f.unit,
      priceCarga: f.unit === 'carga' ? f.priceCarga : null,
      notes: f.notes,
      harvest: { es: 'Cosecha 2026', en: 'Harvest 2026' },
      photo: SHAREABLE_PHOTOS[f.photo].src,
    });
    setDoneId(id);
  };

  if (doneId) {
    return (
      <div className="screen publish-done">
        <div className="screen-body center">
          <div className="success-check pop-in"><Icon name="check" size={64} stroke={3} /></div>
          <h2>¡Lote publicado!</h2>
          <p className="muted">Ya lo pueden ver compradores en Alemania, Estados Unidos, Japón y más.</p>
          <button className="btn btn-primary btn-lg btn-block" onClick={() => navigate(`/lot/${doneId}`, { replace: true })}>
            <Icon name="eye" /> Ver mi lote
          </button>
          <button className="btn btn-ghost btn-lg btn-block" onClick={() => navigate('/home', { replace: true })}>
            Ir al inicio
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="screen publish">
      <TopBar title="Publicar lote" subtitle="5 pasos sencillos" />
      <div className="screen-body">
        <section className="step">
          <h3><span className="step-n">1</span> ¿Qué variedad?</h3>
          <div className="chip-wrap big">
            {VARIETIES.map((v) => (
              <button key={v} className={`chip ${f.variety === v ? 'active' : ''}`} onClick={() => set('variety', v)}>{v}</button>
            ))}
          </div>
        </section>

        <section className="step">
          <h3><span className="step-n">2</span> ¿Qué proceso?</h3>
          <div className="process-pick">
            {Object.entries(PROCESSES).map(([k, p]) => (
              <button key={k} className={f.process === k ? 'active' : ''} onClick={() => set('process', k)}>
                <span>{p.icon}</span>
                <b>{p.es}</b>
              </button>
            ))}
          </div>
        </section>

        <section className="step">
          <h3><span className="step-n">3</span> ¿Cuántos sacos de 70 kg?</h3>
          <Stepper value={f.sacks} min={1} max={200} onChange={(v) => set('sacks', v)} label={`sacos · ${f.sacks * 70} kg`} />
        </section>

        <section className="step">
          <h3><span className="step-n">4</span> Puntaje SCA</h3>
          <Stepper value={f.sca} min={78} max={95} step={0.5} onChange={(v) => set('sca', v)} label="puntos" />
          {f.sca < 80 && <p className="warn"><Icon name="info" size={14} /> CaféDirecto recibe cafés de 80 puntos o más.</p>}
        </section>

        <section className="step">
          <h3><span className="step-n">5</span> Su precio</h3>
          <Segmented
            value={f.unit}
            onChange={(v) => set('unit', v)}
            options={[{ value: 'lb', label: 'Por libra (USD)' }, { value: 'carga', label: 'Por carga (COP)' }]}
          />
          <div className="mt">
            {f.unit === 'lb' ? (
              <Stepper value={f.priceLb} min={1} max={40} step={0.1} onChange={(v) => set('priceLb', v)} format={(v) => fmtUSD(v, 'es')} label="por libra" />
            ) : (
              <>
                <Stepper value={f.priceCarga} min={1000000} max={20000000} step={50000} onChange={(v) => set('priceCarga', v)} format={fmtCOP} label="por carga (125 kg pergamino)" />
                <p className="muted small center">≈ {fmtUSD(priceLb, 'es')} por libra de café verde (aprox.)</p>
              </>
            )}
          </div>
          <div className="total-box">
            <span>Si vende todo el lote</span>
            <b>{fmtUSD(quoteTotal(priceLb, f.sacks), 'es', 0)}</b>
          </div>
        </section>

        <section className="step optional">
          <h3><span className="step-n">+</span> Sabores en la taza <small>(opcional)</small></h3>
          <div className="chip-wrap">
            {NOTE_OPTIONS.map((n) => (
              <button
                key={n}
                className={`chip ${f.notes.includes(n) ? 'active' : ''}`}
                onClick={() => set('notes', f.notes.includes(n) ? f.notes.filter((x) => x !== n) : [...f.notes, n].slice(-4))}
              >
                {NOTES[n].es}
              </button>
            ))}
          </div>
          <h3 className="mt"><span className="step-n">+</span> Foto del lote</h3>
          <div className="photo-pick">
            {SHAREABLE_PHOTOS.map((p, i) => (
              <button key={p.src} className={f.photo === i ? 'active' : ''} onClick={() => set('photo', i)}>
                <Img src={p.src} alt="" />
                {f.photo === i && <span className="photo-check"><Icon name="check" size={16} stroke={3} /></span>}
              </button>
            ))}
          </div>
          <label className="field mt">
            <span>Nombre del lote (opcional)</span>
            <input value={f.name} onChange={(e) => set('name', e.target.value)} placeholder={`Lote ${f.variety}`} />
          </label>
        </section>
      </div>
      <div className="screen-footer">
        <button className="btn btn-primary btn-lg btn-block" onClick={publish} disabled={f.sca < 80}>
          <Icon name="send" /> Publicar lote
        </button>
      </div>
    </div>
  );
}
