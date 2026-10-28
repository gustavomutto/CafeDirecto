import { useMemo, useState } from 'react';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import LotCard from '../components/LotCard';
import { EmptyState, Sheet } from '../components/ui';
import { PROCESSES, REGIONS, VARIETIES } from '../data/catalog';
import { NOTES } from '../data/catalog';
import { firstName, fmtNum } from '../utils';

const DEFAULTS = { regions: [], processes: [], varieties: [], minScore: 80, minAlt: 1400 };

/** Explorar y filtrar (comprador) — RF-07 */
export default function Explore() {
  const { state, meBuyer } = useApp();
  const [q, setQ] = useState('');
  const [f, setF] = useState(DEFAULTS);
  const [draft, setDraft] = useState(DEFAULTS);
  const [open, setOpen] = useState(false);

  const toggle = (obj, key, val) => ({
    ...obj,
    [key]: obj[key].includes(val) ? obj[key].filter((x) => x !== val) : [...obj[key], val],
  });

  const activeCount =
    f.processes.length + f.varieties.length + (f.minScore > 80 ? 1 : 0) + (f.minAlt > 1400 ? 1 : 0);

  const results = useMemo(() => {
    const text = q.trim().toLowerCase();
    return state.lots
      .filter((l) => l.sacks > 0)
      .filter((l) => {
        const farm = state.farms.find((x) => x.id === l.farmId);
        if (f.regions.length && !f.regions.includes(farm.region)) return false;
        if (f.processes.length && !f.processes.includes(l.process)) return false;
        if (f.varieties.length && !f.varieties.includes(l.variety)) return false;
        if (l.sca < f.minScore) return false;
        if (farm.altitude < f.minAlt) return false;
        if (text) {
          const hay = [l.name, l.variety, farm.name, farm.producer, farm.region, farm.municipality, ...l.notes.map((n) => NOTES[n]?.en)]
            .join(' ')
            .toLowerCase();
          if (!hay.includes(text)) return false;
        }
        return true;
      })
      .sort((a, b) => (b.isNew ? 1 : 0) - (a.isNew ? 1 : 0) || b.createdAt - a.createdAt);
  }, [state.lots, state.farms, f, q]);

  return (
    <div className="screen explore">
      <div className="screen-body">
        <header className="explore-head">
          <p className="eyebrow">Good morning, {firstName(meBuyer.contact)} ☀️</p>
          <h1>Discover Colombian<br />specialty origins</h1>
          <div className="search">
            <Icon name="compass" size={18} />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search farm, variety, flavor…"
              aria-label="Search"
            />
            {q && <button onClick={() => setQ('')} aria-label="Clear"><Icon name="x" size={16} /></button>}
          </div>
        </header>

        <div className="chip-scroll">
          <button className={`chip ${f.regions.length === 0 ? 'active' : ''}`} onClick={() => setF({ ...f, regions: [] })}>
            All regions
          </button>
          {REGIONS.map((r) => (
            <button key={r} className={`chip ${f.regions.includes(r) ? 'active' : ''}`} onClick={() => setF(toggle(f, 'regions', r))}>
              {r}
            </button>
          ))}
        </div>

        <div className="results-bar">
          <span><b>{results.length}</b> lots · direct from farm</span>
          <button className={`filter-btn ${activeCount ? 'has' : ''}`} onClick={() => { setDraft(f); setOpen(true); }}>
            <Icon name="filter" size={16} /> Filters{activeCount ? ` · ${activeCount}` : ''}
          </button>
        </div>

        <div className="lot-list">
          {results.map((l) => <LotCard key={l.id} lot={l} />)}
          {results.length === 0 && (
            <EmptyState
              icon="🔎"
              title="No lots match these filters"
              action={<button className="btn btn-outline" onClick={() => { setF(DEFAULTS); setQ(''); }}>Clear filters</button>}
            />
          )}
        </div>
      </div>

      <Sheet
        open={open}
        onClose={() => setOpen(false)}
        title="Filters"
        footer={
          <div className="row gap">
            <button className="btn btn-ghost" onClick={() => setDraft({ ...DEFAULTS, regions: f.regions })}>Reset</button>
            <button className="btn btn-primary btn-block" onClick={() => { setF(draft); setOpen(false); }}>Show results</button>
          </div>
        }
      >
        <h4 className="filter-title">Process</h4>
        <div className="chip-wrap">
          {Object.entries(PROCESSES).map(([k, p]) => (
            <button key={k} className={`chip ${draft.processes.includes(k) ? 'active' : ''}`} onClick={() => setDraft(toggle(draft, 'processes', k))}>
              {p.icon} {p.en}
            </button>
          ))}
        </div>
        <h4 className="filter-title">Variety</h4>
        <div className="chip-wrap">
          {VARIETIES.map((v) => (
            <button key={v} className={`chip ${draft.varieties.includes(v) ? 'active' : ''}`} onClick={() => setDraft(toggle(draft, 'varieties', v))}>
              {v}
            </button>
          ))}
        </div>
        <h4 className="filter-title">Minimum SCA score <b>{draft.minScore}+</b></h4>
        <input type="range" min="80" max="89" step="1" value={draft.minScore} onChange={(e) => setDraft({ ...draft, minScore: +e.target.value })} />
        <div className="range-labels"><span>80</span><span>89</span></div>
        <h4 className="filter-title">Minimum altitude <b>{fmtNum(draft.minAlt)} m</b></h4>
        <input type="range" min="1400" max="2200" step="50" value={draft.minAlt} onChange={(e) => setDraft({ ...draft, minAlt: +e.target.value })} />
        <div className="range-labels"><span>1,400 m</span><span>2,200 m</span></div>
      </Sheet>
    </div>
  );
}
