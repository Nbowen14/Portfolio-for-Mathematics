import {models, describePoint, curveSegments} from './models.mjs';
import source from './source-data.mjs';

const byId = id => document.getElementById(id);
const escapeHtml = text => text.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#39;');
const number = x => Math.abs(x) < 1e-12 ? '0' : Number(x.toPrecision(5)).toString();
const plot = byId('function-plot');
const select = byId('function-select');
const slider = byId('point');

function renderExplorer() {
  const id = select.value;
  const a = Number(slider.value);
  const model = models[id];
  const result = describePoint(id,a);
  const left=49, right=617, top=19, bottom=350;
  const x = v => left+(v+2)/4*(right-left);
  const y = v => bottom-(v-model.y[0])/(model.y[1]-model.y[0])*(bottom-top);
  const title = `${model.name} at a = ${number(a)}`;
  let svg = `<title id="plot-title">${escapeHtml(title)}</title><desc id="plot-description">${escapeHtml(result.message)}</desc><defs><clipPath id="plot-clip"><rect x="${left}" y="${top}" width="${right-left}" height="${bottom-top}"/></clipPath></defs>`;
  for(let v=-2;v<=2;v+=0.5) {
    svg += `<line x1="${x(v)}" y1="${top}" x2="${x(v)}" y2="${bottom}" stroke="${v===0?'#b4c1b6':'#e5e8df'}" stroke-width="${v===0?1.2:0.8}"/>`;
    if(Number.isInteger(v)) svg += `<text x="${x(v)}" y="${bottom+19}" text-anchor="middle" fill="#77857c" font-size="11" font-family="monospace">${v}</text>`;
  }
  const yStep = id==='vertical'||id==='jump'?0.5:1;
  for(let v=Math.ceil(model.y[0]/yStep)*yStep;v<=model.y[1];v+=yStep) {
    svg += `<line x1="${left}" y1="${y(v)}" x2="${right}" y2="${y(v)}" stroke="${v===0?'#b4c1b6':'#e5e8df'}" stroke-width="${v===0?1.2:0.8}"/><text x="${left-12}" y="${y(v)+4}" text-anchor="end" fill="#77857c" font-size="11" font-family="monospace">${v}</text>`;
  }
  svg += `<text x="${right}" y="${bottom+35}" text-anchor="end" fill="#77857c" font-size="12" font-family="Georgia" font-style="italic">x</text><text x="${left-20}" y="12" fill="#77857c" font-size="12" font-family="Georgia" font-style="italic">f(x)</text><g clip-path="url(#plot-clip)">`;
  for(const points of curveSegments(id)) {
    svg += `<path d="${points.map(([px,py],i)=>`${i?'L':'M'}${x(px).toFixed(3)},${y(py).toFixed(3)}`).join(' ')}" fill="none" stroke="#306b70" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>`;
  }
  if(result.slope!==null) {
    const y0=result.value+result.slope*(-2-a);
    const y1=result.value+result.slope*(2-a);
    svg += `<line x1="${x(-2)}" y1="${y(y0)}" x2="${x(2)}" y2="${y(y1)}" stroke="#ad482c" stroke-width="2" stroke-dasharray="7 5"/>`;
  } else if(id==='vertical') {
    svg += `<line x1="${x(0)}" y1="${top}" x2="${x(0)}" y2="${bottom}" stroke="#ad482c" stroke-width="2" stroke-dasharray="7 5"/>`;
  }
  if(id==='jump') svg += `<circle cx="${x(0)}" cy="${y(0)}" r="5.5" fill="#fffefa" stroke="#306b70" stroke-width="2"/><circle cx="${x(0)}" cy="${y(1)}" r="5.5" fill="#306b70"/>`;
  svg += `<circle cx="${x(a)}" cy="${y(result.value)}" r="10" fill="#ad482c" fill-opacity="0.12"/><circle cx="${x(a)}" cy="${y(result.value)}" r="4.5" fill="#ad482c" stroke="#fffefa" stroke-width="2"/></g>`;
  plot.innerHTML=svg;
  byId('formula').textContent=model.formula;
  byId('formula').style.fontSize=id==='corner'||id==='jump'?'19px':'';
  byId('point-value').value=a.toFixed(2);
  byId('slope-value').textContent=result.slope===null?'No finite derivative':`f′(a) = ${number(result.slope)}`;
  byId('tangent-key').textContent=result.slope!==null?'Exact tangent':id==='vertical'?'Vertical tangent':'No tangent';
  byId('explorer-result').textContent=result.message;
  byId('explorer-result').classList.toggle('exception',result.exceptional);
}

select.addEventListener('change',()=>{slider.value=select.value==='smooth'?'1':'0';renderExplorer();});
slider.addEventListener('input',renderExplorer);
byId('reset-point').addEventListener('click',()=>{slider.value='0';renderExplorer();});
renderExplorer();

let activeSection='models';
const tabs=Array.from(document.querySelectorAll('[data-section]'));
const tokenPattern=/(#.*$)|("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')|\b(function|if|else|for|in|return|TRUE|FALSE|NULL|NA_real_|NA_character_|NA|Inf)\b|\b(\d+(?:\.\d*)?(?:e[+-]?\d+)?L?)\b|(<-|&&|\|\||==|!=|<=|>=|%in%)/g;

function highlight(line) {
  let result='',end=0;
  for(const m of line.matchAll(tokenPattern)) {
    result += escapeHtml(line.slice(end,m.index));
    const kind=m[1]?'comment':m[2]?'string':m[3]?'keyword':m[4]?'number':'operator';
    result += `<span class="tok-${kind}">${escapeHtml(m[0])}</span>`;
    end=m.index+m[0].length;
  }
  return result+escapeHtml(line.slice(end));
}

function renderCode(id, focus=false) {
  if(!source?.sections?.[id]) return;
  activeSection=id;
  const section=source.sections[id];
  tabs.forEach(tab=>{const active=tab.dataset.section===id;tab.setAttribute('aria-selected',String(active));tab.tabIndex=active?0:-1;if(active&&focus)tab.focus();});
  byId('source-code').innerHTML=section.code.replace(/\n$/,'').split('\n').map((line,i)=>`<span class="code-line" data-line="${section.start+i}">${highlight(line)||' '}</span>`).join('');
  byId('code-description').textContent=section.description;
  byId('code-panel').setAttribute('aria-labelledby',`tab-${id}`);
  byId('code-panel').scrollTop=0;
  byId('code-panel').scrollLeft=0;
  byId('code-range').textContent=`Lines ${section.start}–${section.start+section.code.trimEnd().split('\n').length-1} / ${source.lineCount}`;
  byId('code-count').textContent=`${source.lineCount} lines · refined version`;
  byId('copy-status').textContent='';
}
tabs.forEach((tab,index)=>{
  tab.addEventListener('click',()=>renderCode(tab.dataset.section));
  tab.addEventListener('keydown',event=>{
    let next;
    if(event.key==='ArrowRight')next=(index+1)%tabs.length;
    if(event.key==='ArrowLeft')next=(index+tabs.length-1)%tabs.length;
    if(event.key==='Home')next=0;
    if(event.key==='End')next=tabs.length-1;
    if(next!==undefined){event.preventDefault();renderCode(tabs[next].dataset.section,true);}
  });
});
byId('copy-code').addEventListener('click',async()=>{
  if(!source?.sections?.[activeSection])return;
  const text=source.sections[activeSection].code;
  try {
    if(!navigator.clipboard?.writeText)throw new Error('Clipboard unavailable');
    await navigator.clipboard.writeText(text);
    byId('copy-status').textContent=activeSection==='full'?'Complete app.R copied.':'Selected code section copied. Choose Full app.R to copy the complete application.';
  } catch {
    const range=document.createRange();range.selectNodeContents(byId('source-code'));
    const selection=window.getSelection();selection.removeAllRanges();selection.addRange(range);
    byId('copy-status').textContent='Code selected. Press Ctrl+C (Windows) or Command+C (Mac) to copy.';
  }
});
if(source)renderCode(activeSection);else byId('source-code').textContent='Use Download app.R to read the complete source.';
