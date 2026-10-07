import { createClient } from '@supabase/supabase-js'
export const configured = Boolean(import.meta.env.VITE_SUPABASE_URL && import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY)
export const backend = configured ? createClient(import.meta.env.VITE_SUPABASE_URL, import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY) : null
const image = id => `https://images.unsplash.com/${id}?auto=format&fit=crop&w=640&q=85`
export const demoProducts = [
 ['มะเขือเทศสด','VEG-001','ผักและผลไม้',35,24,'กก.','photo-1546094096-0df4bcaaa337'],
 ['ไข่ไก่สด เบอร์ 2','EGG-001','เนื้อสัตว์และไข่',65,18,'แพ็ก','photo-1518569656558-1f25e69d93d7'],
 ['นมสดรสจืด','DRK-001','เครื่องดื่ม',42,8,'ขวด','photo-1563636619-e9143da7973b'],
 ['ข้าวหอมมะลิ 100%','DRY-001','อาหารแห้ง',189,32,'ถุง','photo-1586201375761-83865001e31c'],
 ['กล้วยหอมทอง','FRT-001','ผักและผลไม้',45,15,'แพ็ก','photo-1603833665858-e61d17a86224'],
 ['บรอกโคลีสด','VEG-002','ผักและผลไม้',55,6,'กก.','photo-1459411621453-7b03977f4bfc'],
 ['น้ำส้มคั้นสด','DRK-002','เครื่องดื่ม',59,20,'ขวด','photo-1600271886742-f049cd451bba'],
 ['ขนมปังโฮลวีต','DRY-002','อาหารแห้ง',39,0,'แพ็ก','photo-1509440159596-0249088772ff'],
].map((p,i)=>({id:`demo-${i}`,name:p[0],sku:p[1],category:p[2],price:p[3],stock:p[4],unit:p[5],image_url:image(p[6]),description:'',updated_at:new Date(Date.now()-i*60000).toISOString()}))
const key='baan-market-products-v1'
function localProducts() { const saved=localStorage.getItem(key); return saved ? JSON.parse(saved) : structuredClone(demoProducts) }
export async function loadProducts() {
 if(!backend) return localProducts()
 const {data,error}=await backend.from('products').select('*').order('updated_at',{ascending:false});if(error) throw error;return data
}
export async function saveProduct(product,id,file) {
 const payload={name:product.name,sku:product.sku,category:product.category,price:product.price,stock:product.stock,unit:product.unit,image_url:product.image_url,description:product.description}
 if(!backend) {
  const saved={...payload,id:id??crypto.randomUUID(),updated_at:new Date().toISOString()};const list=localProducts();const index=list.findIndex(p=>p.id===id);if(index>=0) list[index]=saved;else list.unshift(saved);localStorage.setItem(key,JSON.stringify(list));return saved
 }
 let uploadedPath=null
 if(file) {
  const {data:{user}}=await backend.auth.getUser();if(!user) throw new Error('กรุณาเข้าสู่ระบบก่อนอัปโหลดรูป')
  uploadedPath=`${user.id}/${crypto.randomUUID()}.${file.type.split('/')[1]}`
  const {error}=await backend.storage.from('product-images').upload(uploadedPath,file);if(error) throw error
  payload.image_url=backend.storage.from('product-images').getPublicUrl(uploadedPath).data.publicUrl
 }
 const query=id ? backend.from('products').update(payload).eq('id',id) : backend.from('products').insert(payload)
 const {data,error}=await query.select().single();if(error) {if(uploadedPath) await backend.storage.from('product-images').remove([uploadedPath]);throw error}return data
}
