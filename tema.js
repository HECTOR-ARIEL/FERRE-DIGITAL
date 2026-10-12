// Modo claro / oscuro. Cada persona elige el suyo y queda guardado en su teléfono o computadora.
// "Auto" sigue la configuración del dispositivo. Se carga en el <head> para que la página no parpadee.
const TEMAS = ['auto', 'claro', 'oscuro'],
  TEMA_TXT = { auto: '◐ Auto', claro: '☀ Claro', oscuro: '☾ Oscuro' };
function leeTema() { try { return localStorage.getItem('tema') } catch { return null } }
function ponTema(t) {
  if (!TEMAS.includes(t)) t = 'auto';
  const h = document.documentElement;
  if (t === 'auto') h.removeAttribute('data-theme'); else h.dataset.theme = t === 'claro' ? 'light' : 'dark';
  const b = document.getElementById('tema');
  if (b) { const [i, x] = TEMA_TXT[t].split(' '); b.innerHTML = i + '<span class="tx"> ' + x + '</span>'; b.title = 'Tema: ' + x + ' (tocar para cambiar)' }
  return t;
}
function cambiarTema() {
  const t = ponTema(TEMAS[(TEMAS.indexOf(leeTema() || 'auto') + 1) % TEMAS.length]);
  try { localStorage.setItem('tema', t) } catch { }
}
ponTema(leeTema());
document.addEventListener('DOMContentLoaded', () => ponTema(leeTema()));
