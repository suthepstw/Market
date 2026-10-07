<script setup>
import { computed, onMounted, ref } from 'vue'
import Icon from './components/Icon.vue'
import { backend, configured, loadProducts, saveProduct } from './lib/store.js'
const products=ref([]),search=ref(''),category=ref('ทั้งหมด'),status=ref('ทั้งหมด'),sort=ref('ล่าสุด'),view=ref('grid')
const loading=ref(true),saving=ref(false),modal=ref(false),notice=ref(''),error=ref(''),editing=ref(null),imageFile=ref(null)
const authModal=ref(false),email=ref(''),password=ref(''),user=ref(null),authBusy=ref(false)
const categories=['ทั้งหมด','ผักและผลไม้','เนื้อสัตว์และไข่','เครื่องดื่ม','อาหารแห้ง','ของใช้ในบ้าน']
const blank=()=>({name:'',sku:'',category:'ผักและผลไม้',price:'',stock:'',unit:'ชิ้น',image_url:'',description:''})
const form=ref(blank())
const filtered=computed(()=>products.value.filter(p=>(category.value==='ทั้งหมด'||p.category===category.value)&&(!search.value||`${p.name} ${p.sku}`.toLowerCase().includes(search.value.toLowerCase()))&&(status.value==='ทั้งหมด'||(status.value==='สต็อกต่ำ'?p.stock>0&&p.stock<=10:status.value==='หมดสต็อก'?p.stock===0:p.stock>0))).sort((a,b)=>sort.value==='ราคา: ต่ำไปสูง'?a.price-b.price:sort.value==='ราคา: สูงไปต่ำ'?b.price-a.price:sort.value==='ชื่อสินค้า'?a.name.localeCompare(b.name,'th'):new Date(b.updated_at)-new Date(a.updated_at)))
const lowStock=computed(()=>products.value.filter(p=>p.stock>0&&p.stock<=10).length)
const totalValue=computed(()=>products.value.reduce((s,p)=>s+p.price*p.stock,0))
const money=n=>Number(n).toLocaleString('th-TH',{minimumFractionDigits:2,maximumFractionDigits:2})
function toast(message){notice.value=message;setTimeout(()=>notice.value='',4000)}
function openForm(product){if(configured&&!user.value){authModal.value=true;error.value='';return}error.value='';editing.value=product?.id??null;form.value=product?{...product}:blank();imageFile.value=null;modal.value=true}
function reset(){category.value='ทั้งหมด';status.value='ทั้งหมด';search.value=''}
async function refresh(){loading.value=true;error.value='';try{products.value=await loadProducts()}catch(e){error.value=e.message}finally{loading.value=false}}
async function selectImage(event){
 const file=event.target.files[0];if(!file)return
 if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>5*1024*1024){error.value='กรุณาเลือกรูป JPG, PNG หรือ WebP ขนาดไม่เกิน 5 MB';return}
 imageFile.value=file;error.value='';form.value.image_url=await new Promise((resolve,reject)=>{const r=new FileReader();r.onload=()=>resolve(r.result);r.onerror=reject;r.readAsDataURL(file)})
}
async function submit(){
 saving.value=true;error.value=''
 try{
  if(!form.value.name.trim()||!form.value.sku.trim()||form.value.price===''||form.value.stock===''||!Number.isFinite(Number(form.value.price))||Number(form.value.price)<0||!Number.isInteger(Number(form.value.stock))||Number(form.value.stock)<0)throw new Error('กรุณากรอกข้อมูลสินค้า ราคา และจำนวนให้ถูกต้อง')
  if(products.value.some(p=>p.sku.toLowerCase()===form.value.sku.trim().toLowerCase()&&p.id!==editing.value))throw new Error('รหัสสินค้านี้มีอยู่แล้ว กรุณาใช้รหัสอื่น')
  if(form.value.image_url&&!imageFile.value&&!/^https?:\/\//.test(form.value.image_url)&&!(!configured&&/^data:image\/(jpeg|png|webp);base64,/.test(form.value.image_url)))throw new Error('ลิงก์รูปภาพต้องขึ้นต้นด้วย https:// หรือ http://')
  const saved=await saveProduct({...form.value,name:form.value.name.trim(),sku:form.value.sku.trim(),price:Number(form.value.price),stock:Number(form.value.stock)},editing.value,imageFile.value)
  const index=products.value.findIndex(p=>p.id===saved.id);if(index>=0)products.value[index]=saved;else products.value.unshift(saved)
  modal.value=false;toast(editing.value?'บันทึกการแก้ไขสินค้าแล้ว':'เพิ่มสินค้าเรียบร้อยแล้ว')
 }catch(e){error.value=e.message}finally{saving.value=false}
}
async function login(){authBusy.value=true;error.value='';try{const{data,error:err}=await backend.auth.signInWithPassword({email:email.value,password:password.value});if(err)throw err;user.value=data.user;authModal.value=false;password.value='';toast('เข้าสู่ระบบเรียบร้อยแล้ว')}catch(e){error.value=e.message}finally{authBusy.value=false}}
async function profile(){if(!configured){toast('ตั้งค่า Supabase ในไฟล์ .env เพื่อเข้าสู่ระบบ');return}if(!user.value){error.value='';authModal.value=true;return}const{error:err}=await backend.auth.signOut();if(err){toast(err.message);return}user.value=null}
function exportCsv(){const rows=[['รหัสสินค้า','ชื่อสินค้า','หมวดหมู่','ราคา','คงเหลือ','หน่วย'],...filtered.value.map(p=>[p.sku,p.name,p.category,p.price,p.stock,p.unit])];const csv='\uFEFF'+rows.map(row=>row.map(v=>'"'+String(v).replace(/"/g,'""').replace(/^[=+@-]/,"'")+'"').join(',')).join('\r\n');const url=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8;'}));const a=document.createElement('a');a.href=url;a.download='baan-market-products.csv';a.click();URL.revokeObjectURL(url);toast('ส่งออกรายการสินค้าแล้ว')}
onMounted(async()=>{if(configured){const{data}=await backend.auth.getSession();user.value=data.session?.user??null;backend.auth.onAuthStateChange((_event,session)=>user.value=session?.user??null)}await refresh()})
</script>

<template>
 <div class="app-shell">
  <aside class="sidebar">
   <a class="brand" href="#"><span class="brand-mark"><Icon name="store" :size="26"/></span><span>บ้านมาร์เก็ต<small>BAAN MARKET</small></span></a>
   <div class="shop-card"><span class="shop-avatar"><Icon name="store"/></span><div><strong>ร้านของชำของฉัน</strong><small>จัดการร้านให้เป็นเรื่องง่าย</small></div><Icon name="chevron" :size="14"/></div>
   <p class="nav-caption">พื้นที่ทำงาน</p>
   <button class="nav-item" @click="reset();toast('แสดงภาพรวมสินค้าทั้งหมด')"><Icon name="dashboard"/>ภาพรวมร้านค้า</button>
   <button class="nav-item active" @click="reset"><Icon name="box"/>จัดการสินค้า<span class="nav-count">{{products.length}}</span></button>
   <button class="nav-item" @click="status='สต็อกต่ำ';category='ทั้งหมด'"><Icon name="layers"/>สต็อกสินค้า<span v-if="lowStock" class="nav-dot"></span></button>
   <div class="sidebar-bottom"><div class="support-card"><span class="support-icon"><Icon name="leaf" :size="25"/></span><strong>ร้านเล็ก ๆ เติบโตได้ทุกวัน</strong><p>จัดการสินค้าให้พร้อมขาย<br>แล้วให้เราช่วยดูแลที่เหลือ</p><span class="support-label">เพื่อนคู่ใจร้านของชำ <Icon name="heart" :size="13"/></span></div><div class="connection"><span :class="['connection-dot',{demo:!configured}]"></span>{{configured?'เชื่อมต่อ Supabase แล้ว':'โหมดสาธิต · บันทึกในเครื่อง'}}</div><button class="profile" @click="profile"><span class="avatar">{{user?user.email[0].toUpperCase():'บ'}}</span><span><strong>{{user?'ผู้ดูแลร้าน':'เจ้าของร้าน'}}</strong><small>{{configured?(user?'คลิกเพื่อออกจากระบบ':'เข้าสู่ระบบเพื่อแก้ไข'):'บัญชีสาธิต'}}</small></span><Icon name="logout" :size="17"/></button></div>
  </aside>
  <div class="workspace">
   <header class="topbar"><div class="breadcrumb">ร้านของชำของฉัน <Icon name="chevron" :size="14"/><strong>จัดการสินค้า</strong></div><div class="topbar-right"><span class="today">{{new Date().toLocaleDateString('th-TH',{day:'numeric',month:'long',year:'numeric'})}}</span><span class="top-divider"></span><button class="avatar small" aria-label="บัญชีผู้ใช้" @click="profile">บ</button></div></header>
   <main>
    <div class="page-heading"><div><div class="eyebrow">YOUR EVERYDAY STORE, SIMPLIFIED</div><h1>จัดการสินค้า<span class="heading-dot">.</span></h1><p>สินค้าทุกชิ้น ราคาทุกวัน จัดการได้ในที่เดียว</p></div><button class="primary" @click="openForm()"><Icon name="plus" :size="19"/>เพิ่มสินค้าใหม่</button></div>
    <section class="stats">
     <article class="stat-card"><div><span class="stat-label">สินค้าทั้งหมด</span><div class="stat-number">{{products.length}}<small>รายการ</small></div><span class="stat-note">สินค้าภายในร้านของคุณ</span></div><span class="stat-icon green"><Icon name="box" :size="23"/></span></article>
     <article class="stat-card"><div><span class="stat-label">พร้อมจำหน่าย</span><div class="stat-number">{{products.filter(p=>p.stock>0).length}}<small>รายการ</small></div><span class="stat-note"><span class="tiny-dot"></span>พร้อมสำหรับลูกค้าของคุณ</span></div><span class="stat-icon blue"><Icon name="check" :size="23"/></span></article>
     <article class="stat-card"><div><span class="stat-label">สินค้าใกล้หมด</span><div class="stat-number">{{lowStock}}<small>รายการ</small></div><button class="stat-note amber-text" @click="status='สต็อกต่ำ';category='ทั้งหมด'">เช็กสต็อกและเติมสินค้า <Icon name="arrow" :size="13"/></button></div><span class="stat-icon amber"><Icon name="alert" :size="23"/></span></article>
     <article class="stat-card"><div><span class="stat-label">มูลค่าสินค้าในสต็อก</span><div class="stat-number value"><small class="currency">฿</small>{{money(totalValue).split('.')[0]}}</div><span class="stat-note">คำนวณจากราคาขายปัจจุบัน</span></div><span class="stat-icon violet"><Icon name="wallet" :size="23"/></span></article>
    </section>
    <section class="catalog">
     <div class="catalog-heading"><h2>สินค้าของร้าน <span>{{products.length}} รายการ</span></h2><button class="outline" @click="exportCsv"><Icon name="download" :size="16"/>ส่งออกข้อมูล</button></div>
     <div class="catalog-tools"><label class="search"><Icon name="search" :size="19"/><input v-model="search" placeholder="ค้นหาชื่อสินค้า หรือรหัสสินค้า..." aria-label="ค้นหาสินค้า"/><span class="search-hint">ค้นหา</span></label><div class="filter-controls"><label class="select-wrap"><Icon name="filter" :size="16"/><select v-model="status" aria-label="สถานะสินค้า"><option>ทั้งหมด</option><option>พร้อมจำหน่าย</option><option>สต็อกต่ำ</option><option>หมดสต็อก</option></select></label><label class="select-wrap sort"><Icon name="sort" :size="16"/><select v-model="sort" aria-label="เรียงสินค้า"><option>ล่าสุด</option><option>ราคา: ต่ำไปสูง</option><option>ราคา: สูงไปต่ำ</option><option>ชื่อสินค้า</option></select></label><div class="view-switch"><button :class="{selected:view==='grid'}" aria-label="มุมมองการ์ด" @click="view='grid'"><Icon name="grid" :size="18"/></button><button :class="{selected:view==='list'}" aria-label="มุมมองรายการ" @click="view='list'"><Icon name="list" :size="19"/></button></div></div></div>
     <div class="category-tabs"><button v-for="(cat,i) in categories" :key="cat" :class="{selected:category===cat}" @click="category=cat"><Icon v-if="i===0" name="grid" :size="14"/>{{cat}}<span v-if="i===0">{{products.length}}</span></button></div>
     <div class="results-line"><span>แสดง {{filtered.length}} รายการ<span v-if="category!=='ทั้งหมด'"> ในหมวด{{category}}</span></span><span><span class="tiny-dot"></span>{{configured?'ข้อมูลจากร้านของคุณ':'ข้อมูลตัวอย่างสำหรับทดลองใช้งาน'}}</span></div>
     <div v-if="error&&!modal&&!authModal" class="error">{{error}} <button @click="refresh">ลองอีกครั้ง</button></div>
     <div v-if="loading" class="empty">กำลังโหลดสินค้า...</div>
     <div v-else-if="!filtered.length" class="empty"><Icon name="box" :size="36"/><h3>ไม่พบสินค้า</h3><p>ลองค้นหาด้วยคำอื่น หรือเพิ่มสินค้าใหม่ในร้าน</p><button class="outline" @click="reset">แสดงสินค้าทั้งหมด</button></div>
     <div v-else :class="['products',view]">
      <article v-for="product in filtered" :key="product.id" class="product-card">
       <div class="product-image"><img v-if="product.image_url" :src="product.image_url" :alt="product.name" loading="lazy" @error="$event.target.style.opacity='0'"/><Icon v-else name="box" :size="48"/><span :class="['stock-badge',product.stock===0?'out':product.stock<=10?'low':'available']"><span></span>{{product.stock===0?'หมดสต็อก':product.stock<=10?'ใกล้หมด':'พร้อมขาย'}}</span><button class="image-edit" :aria-label="'แก้ไข '+product.name" @click="openForm(product)"><Icon name="edit" :size="16"/></button></div>
       <div class="product-info"><div class="product-category">{{product.category}}</div><h3>{{product.name}}</h3><div class="sku">{{product.sku}}</div><div class="price-row"><div class="price">฿{{money(product.price)}}<span>/ {{product.unit}}</span></div><span class="stock-text" :class="{warning:product.stock<=10}">คงเหลือ <b>{{product.stock}}</b></span></div><div class="product-footer"><span><Icon name="clock" :size="12"/>{{new Date(product.updated_at).toLocaleDateString('th-TH',{day:'numeric',month:'short'})}}</span><button @click="openForm(product)"><Icon name="edit" :size="13"/>แก้ไขสินค้า</button></div></div>
      </article>
     </div>
     <div class="catalog-footer"><span>แสดง {{filtered.length?1:0}}–{{filtered.length}} จาก {{filtered.length}} รายการ</span><span class="page-number">1</span></div>
    </section>
    <footer class="main-footer"><span>บ้านมาร์เก็ต <span class="footer-dot">•</span> เพื่อนคู่ใจร้านของชำ</span><span>ดูแลร้านของคุณ ด้วยความใส่ใจ <Icon name="heart" :size="12"/></span></footer>
   </main>
  </div>
  <div v-if="notice" class="toast" role="status"><Icon name="check" :size="18"/>{{notice}}</div>
  <div v-if="modal" class="modal-backdrop" @click.self="!saving&&(modal=false)" @keydown.esc="!saving&&(modal=false)"><section class="modal" role="dialog" aria-modal="true" aria-labelledby="form-title"><div class="modal-heading"><div><h2 id="form-title">{{editing?'แก้ไขสินค้า':'เพิ่มสินค้าใหม่'}}</h2><p>เติมข้อมูลสินค้าให้พร้อมสำหรับขาย</p></div><button class="icon-button" :disabled="saving" aria-label="ปิด" @click="modal=false"><Icon name="close"/></button></div><form @submit.prevent="submit"><label class="upload"><img v-if="form.image_url" :src="form.image_url" alt="ตัวอย่างรูปสินค้า"/><span><Icon name="upload" :size="24"/><strong>เลือกรูปสินค้า</strong><small>JPG, PNG, WebP · ไม่เกิน 5 MB</small></span><input type="file" accept="image/jpeg,image/png,image/webp" @change="selectImage"/></label><div class="form-grid"><label class="full">ชื่อสินค้า<input v-model="form.name" required maxlength="160" placeholder="เช่น มะเขือเทศสด" autofocus/></label><label>รหัสสินค้า<input v-model="form.sku" required maxlength="40" placeholder="เช่น VEG-001"/></label><label>หมวดหมู่<select v-model="form.category"><option v-for="cat in categories.slice(1)" :key="cat">{{cat}}</option></select></label><label>ราคาขาย (บาท)<input v-model="form.price" type="number" required min="0" step="0.01" placeholder="0.00"/></label><label>จำนวนคงเหลือ<input v-model="form.stock" type="number" required min="0" step="1" placeholder="0"/></label><label>หน่วย<select v-model="form.unit"><option v-for="unit in ['ชิ้น','กก.','แพ็ก','ขวด','ถุง','กล่อง','ฟอง']" :key="unit">{{unit}}</option></select></label><label>ลิงก์รูปภาพ<input v-model="form.image_url" type="text" placeholder="https://..." :disabled="!!imageFile"/></label><label class="full">รายละเอียดสินค้า<textarea v-model="form.description" rows="2" placeholder="รายละเอียดเพิ่มเติม (ไม่บังคับ)"></textarea></label></div><p v-if="error" class="error" role="alert">{{error}}</p><div class="modal-actions"><button type="button" class="outline" :disabled="saving" @click="modal=false">ยกเลิก</button><button class="primary" :disabled="saving">{{saving?'กำลังบันทึก...':'บันทึกสินค้า'}}</button></div></form></section></div>
  <div v-if="authModal" class="modal-backdrop" @click.self="authModal=false"><section class="modal auth-modal" role="dialog" aria-modal="true" aria-labelledby="auth-title"><div class="modal-heading"><h2 id="auth-title">เข้าสู่ระบบเจ้าของร้าน</h2><button class="icon-button" aria-label="ปิด" @click="authModal=false"><Icon name="close"/></button></div><form @submit.prevent="login"><label>อีเมล<input v-model="email" type="email" required autocomplete="username"/></label><label>รหัสผ่าน<input v-model="password" type="password" required autocomplete="current-password"/></label><p v-if="error" class="error">{{error}}</p><button class="primary" :disabled="authBusy">{{authBusy?'กำลังเข้าสู่ระบบ...':'เข้าสู่ระบบ'}}</button></form></section></div>
 </div>
</template>

