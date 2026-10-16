import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {models,describePoint,curveSegments} from '../models.mjs';
import source from '../source-data.mjs';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
assert.equal(source.sections.full.code,fs.readFileSync(path.join(root,'app.R'),'utf8'));
assert.equal(describePoint('smooth',1).slope,2);
assert.equal(describePoint('smooth',0).slope,0);
for(const id of ['absolute','vertical','corner','jump'])assert.equal(describePoint(id,0).slope,null);
assert.equal(describePoint('jump',0).continuous,false);
assert.equal(describePoint('vertical',0).continuous,true);
assert.equal(describePoint('corner',-0.001).slope,-1);
assert.equal(describePoint('corner',0.001).slope,2);
assert.equal(describePoint('jump',-0.001).slope,0);
for(const id of Object.keys(models))for(const segment of curveSegments(id))for(const [x,y]of segment){
  assert.ok(Number.isFinite(x)&&Number.isFinite(y));
  if(id!=='jump')assert.ok(Math.abs(y-models[id].f(x))<1e-10);
}
assert.equal(curveSegments('jump').length,2);

// Exercise event handlers with a small DOM fixture; this is not a browser test.
class Element {
  constructor(id){this.id=id;this.value='';this.textContent='';this.innerHTML='';this.style={};this.attrs={};this.handlers={};this.dataset={};this.classList={toggle(){}};}
  addEventListener(name,handler){this.handlers[name]=handler;}
  setAttribute(name,value){this.attrs[name]=value;}
  focus(){this.focused=true;}
}
const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
const elements=new Map([...html.matchAll(/\bid="([^"]+)"/g)].map(m=>[m[1],new Element(m[1])]));
elements.get('function-select').value='smooth';
elements.get('point').value='1';
const tabs=['models','diagnostics','interface','server','full'].map(id=>{
  const tab=elements.get('tab-'+id);tab.dataset.section=id;return tab;
});
globalThis.document={getElementById:id=>elements.get(id),querySelectorAll:()=>tabs};
let copied='';
Object.defineProperty(globalThis,'navigator',{value:{clipboard:{writeText:async text=>{copied=text;}}},configurable:true});
await import('../app.mjs');
assert.equal(elements.get('slope-value').textContent,'f′(a) = 2');
for(const id of Object.keys(models)){
  elements.get('function-select').value=id;
  elements.get('function-select').handlers.change();
  assert.ok(!/NaN|Infinity/.test(elements.get('function-plot').innerHTML));
  if(id!=='smooth')assert.equal(elements.get('slope-value').textContent,'No finite derivative');
}
elements.get('function-select').value='absolute';
elements.get('point').value='-1';
elements.get('point').handlers.input();
assert.equal(elements.get('slope-value').textContent,'f′(a) = -1');
elements.get('reset-point').handlers.click();
assert.equal(elements.get('point').value,'0');
assert.equal(elements.get('slope-value').textContent,'No finite derivative');
tabs[4].handlers.click();
assert.equal(tabs[4].attrs['aria-selected'],'true');
await elements.get('copy-code').handlers.click();
assert.equal(copied,source.sections.full.code);
assert.equal(elements.get('copy-status').textContent,'Complete app.R copied.');
let prevented=false;
tabs[4].handlers.keydown({key:'ArrowRight',preventDefault(){prevented=true;}});
assert.ok(prevented);
assert.equal(tabs[0].attrs['aria-selected'],'true');
assert.equal(tabs[0].focused,true);
await elements.get('copy-code').handlers.click();
assert.equal(copied,source.sections.models.code);
console.log('PASS: five mathematical models, curve geometry, explorer controls, code tabs, keyboard navigation, and exact source copying.');
