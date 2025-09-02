(function(){
  const TTL = 30*24*60*60*1000, WIDTHS=[400,800,1200]
  const key=(n,w)=>`commons:${w}:${n.toLowerCase()}`
  const get=(n,w)=>{try{let r=localStorage.getItem(key(n,w));if(!r)return;let{url,ts}=JSON.parse(r);return Date.now()-ts<TTL?url:null}catch{}}
  const set=(n,w,u)=>localStorage.setItem(key(n,w),JSON.stringify({url:u,ts:Date.now()}))

  async function fetchUrl(name,w){
    for(const q of [name,`food ${name}`]){
      const res=await fetch(`https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=${encodeURIComponent(q)}&gsrnamespace=6&gsrlimit=1&prop=imageinfo&iiprop=url&iiurlwidth=${w}&format=json&origin=*`)
      const pages=(await res.json())?.query?.pages||{}
      const f=pages[Object.keys(pages)[0]]
      if(f) return f.imageinfo[0].thumburl||f.imageinfo[0].url
    }
  }

  function shimmer(img){img.style.cssText="background:linear-gradient(90deg,#d1d5db 25%,#e5e7eb 37%,#d1d5db 63%);background-size:400% 100%;animation:fd-shimmer 1.2s infinite"}
  function clear(img){img.style.background="";img.style.animation=""}
  function setSrcset(img,url){img.srcset=WIDTHS.map(w=>`${url.replace(/width=\\d+/,'width='+w)} ${w}w`).join(",")}

  async function load(img,name,w){
    let u=get(name,w)||await fetchUrl(name,w)
    u=u||`https://placehold.co/${w}x${Math.round(w*0.66)}?text=${encodeURIComponent(name)}`
    if(u) set(name,w,u)
    const tmp=new Image(); tmp.src=u
    tmp.onload=()=>{if(/width=\\d+/.test(u)) setSrcset(img,u); img.src=u; clear(img)}
    tmp.onerror=()=>{img.src=`https://placehold.co/${w}x${Math.round(w*0.66)}?text=${encodeURIComponent(name)}`; clear(img)}
  }

  function init(){
    document.querySelectorAll('[data-commons-image][data-name]').forEach(img=>{
      if(img.src) return
      shimmer(img)
      const name=img.dataset.name, w=+img.dataset.width||600
      if("IntersectionObserver"in window){
        new IntersectionObserver(es=>es.forEach(e=>{if(e.isIntersecting){e.target.src||load(e.target,name,w);e.target&&e.target.style&&e.target.getAttribute&&e.target;}}),{rootMargin:"300px"}).observe(img)
      } else load(img,name,w)
    })
  }

  (window.Turbo?document.addEventListener("turbo:load",init):document.addEventListener("DOMContentLoaded",init))
  const s=document.createElement("style");s.textContent="@keyframes fd-shimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}";document.head.appendChild(s)
})();
