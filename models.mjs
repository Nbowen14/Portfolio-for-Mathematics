export const models = {
  smooth: {name: 'Quadratic', formula: 'f(x) = x²', f: x => x*x, slope: x => 2*x, y: [-0.65, 4.5]},
  absolute: {name: 'Absolute value', formula: 'f(x) = |x|', f: x => Math.abs(x), slope: x => x === 0 ? null : Math.sign(x), y: [-0.45, 2.4]},
  vertical: {name: 'Cube root', formula: 'f(x) = ∛x', f: x => Math.cbrt(x), slope: x => x === 0 ? null : 1/(3*Math.abs(x)**(2/3)), y: [-1.6, 1.6]},
  corner: {name: 'Piecewise corner', formula: 'f(x) = −x (x < 0); 2x (x ≥ 0)', f: x => x < 0 ? -x : 2*x, slope: x => x === 0 ? null : x < 0 ? -1 : 2, y: [-0.65, 4.5]},
  jump: {name: 'Jump', formula: 'f(x) = 0 (x < 0); 1 (x ≥ 0)', f: x => x < 0 ? 0 : 1, slope: x => x === 0 ? null : 0, y: [-0.4, 1.6]}
};

export function describePoint(id, a) {
  const model = models[id];
  if (!model || !Number.isFinite(a)) throw new Error('Choose a function and a finite point.');
  const slope = model.slope(a);
  const exceptional = slope === null;
  let message = 'Both sides support one finite slope. The function is differentiable here.';
  if (exceptional) message = {
    absolute: 'Continuous at zero, but the slopes are −1 and +1. This corner has no derivative.',
    vertical: 'Continuous at zero with a vertical tangent. Its slope is unbounded, so no finite derivative exists.',
    corner: 'Continuous at zero, but the slopes are −1 and +2. The unequal slopes create a corner.',
    jump: 'The left limit is 0 and the right limit is 1. This discontinuity prevents differentiability.'
  }[id];
  return {value: model.f(a), slope, exceptional, continuous: !(id === 'jump' && a === 0), message};
}

export function curveSegments(id, count = 480) {
  if (!models[id]) throw new Error('Unknown model.');
  if (id === 'jump') return [[[-2,0],[0,0]],[[0,1],[2,1]]];
  if (id === 'vertical') {
    const bound = Math.cbrt(2);
    return [Array.from({length: count+1}, (_,i) => {
      const y = -bound + 2*bound*i/count;
      return [y*y*y,y];
    })];
  }
  return [Array.from({length: count+1}, (_,i) => {
    const x = -2+4*i/count;
    return [x,models[id].f(x)];
  })];
}
