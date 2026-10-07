# บ้านมาร์เก็ต

แอป Vue 3 + Vite สำหรับจัดการร้านของชำ รองรับหน้ารายการสินค้า เพิ่มสินค้า แก้ไขราคา สต็อก และรูปภาพ ค้นหา กรองหมวดหมู่และสถานะ เรียงราคา มุมมองการ์ด/รายการ และส่งออก CSV

## เริ่มใช้งาน

```sh
npm install
npm run dev
```

หากยังไม่ตั้งค่า Supabase แอปจะใช้ข้อมูลตัวอย่างและบันทึกการแก้ไขใน localStorage ของเบราว์เซอร์ (ข้อมูลไม่แชร์ระหว่างเครื่อง) รูปตัวอย่างจาก Unsplash และฟอนต์ Google Fonts ต้องใช้อินเทอร์เน็ต โหมดสาธิตไม่ส่งข้อมูลขึ้น Supabase

## เชื่อม Supabase

1. สร้างโปรเจกต์ Supabase แล้วรัน `supabase/schema.sql` ใน SQL Editor ครั้งเดียว
2. สร้างผู้ดูแลใน Authentication > Users และคัดลอก User UUID
3. รันคำสั่งนี้ใน SQL Editor โดยแทน UUID:

```sql
insert into public.store_admins(user_id) values ('OWNER_USER_UUID');
```

4. คัดลอก `.env.example` เป็น `.env` และกำหนด URL กับ Publishable Key ของโปรเจกต์ (ห้ามใส่ service_role หรือ secret key ใน Vue)
5. เริ่ม dev server ใหม่ แล้วคลิกบัญชีเจ้าของร้านเพื่อเข้าสู่ระบบด้วยอีเมลและรหัสผ่านที่สร้างไว้
6. เพิ่มสินค้าใหม่ผ่านแอป รูป JPG/PNG/WebP ขนาดไม่เกิน 5 MB จะถูกอัปโหลดไป bucket `product-images` ซึ่งแสดงรูปผ่าน public URL

## ฐานข้อมูล

- `products`: ข้อมูลสินค้า รหัสไม่ซ้ำ ชื่อ หมวดหมู่ ราคาขาย จำนวนคงเหลือ หน่วย รูป รายละเอียด และเวลาแก้ไข
- `store_admins`: รายชื่อผู้ดูแลที่จัดการสินค้าของร้านร่วมกัน การให้สิทธิ์ทำได้ผ่าน SQL Editor เท่านั้น
- `product_price_history`: บันทึกราคาเดิม/ใหม่ และผู้แก้ไขโดย trigger อัตโนมัติ ยังไม่มีหน้าจอประวัติราคา

เปิด RLS ทุกตาราง ผู้เข้าชมอ่านรายการสินค้าได้ ผู้ดูแลที่มีชื่อใน `store_admins` เท่านั้นที่เพิ่ม/แก้ไขสินค้าและอัปโหลดรูปได้ ไฟล์เก็บในโฟลเดอร์ UUID ของผู้ดูแล หากบันทึกสินค้าไม่สำเร็จ แอปจะพยายามลบไฟล์ใหม่ที่เพิ่งอัปโหลด รูปเดิมเก็บไว้หลังเปลี่ยนรูปเพื่อไม่กระทบรายการอื่น

## ตรวจสอบ

```sh
npm run build
npm run preview
```

ยังต้องรัน SQL และกำหนด environment ของ Supabase จริงเพื่อทดสอบการเชื่อมต่อ Auth, RLS และ Storage แอปนี้เป็นส่วนจัดการสินค้า ยังไม่มีตะกร้า ชำระเงิน หรือคำสั่งซื้อ

## ขึ้น GitHub และ Cloudflare Pages

สร้าง repository เปล่าบน GitHub โดยไม่เพิ่ม README แล้วรันจากโฟลเดอร์โปรเจกต์นี้ (แทน YOUR_USERNAME และ YOUR_REPOSITORY ด้วยค่าจริง):

```powershell
git init -b main
git add .
git commit -m "Initial grocery store app"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

ไฟล์ `.env`, `node_modules`, `dist` และภาพ preview ถูก ignore แล้ว ให้เก็บ `package-lock.json`, `.env.example` และ `supabase/schema.sql` ใน repository ด้วย

ใน Cloudflare ให้สร้าง **Pages project** แล้วเชื่อม repository จาก GitHub ตั้งค่าดังนี้:

| การตั้งค่า | ค่า |
| --- | --- |
| Production branch | `main` |
| Framework preset | Vue หรือ Vite |
| Build command | `npm run build` |
| Build output directory | `dist` |
| Root directory | ว่าง หาก package.json อยู่บนสุดของ repository |

ไฟล์ `.nvmrc` ระบุ Node.js 22.16.0 สำหรับ build ของ Pages ซึ่งรองรับ Vite ที่ใช้ในโปรเจกต์นี้

เพิ่ม Build environment variables สำหรับ Production ก่อน deploy:

```text
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

ห้ามใช้ service_role หรือ secret key เพราะตัวแปร VITE_ จะรวมอยู่ใน JavaScript ที่เบราว์เซอร์ดาวน์โหลด หากไม่ตั้งค่าสองตัวนี้ เว็บจะเข้าโหมดสาธิต หากแก้ไขค่าภายหลังต้อง deploy ใหม่เพื่อให้ Vite build ด้วยค่าใหม่ ตั้งค่า Preview ด้วยเฉพาะเมื่อจะให้ preview ใช้ฐานข้อมูลนั้นจริง

กด deploy แล้วเปิด URL `https://YOUR_PROJECT.pages.dev` ทดสอบแสดงสินค้า เข้าสู่ระบบด้วยบัญชีผู้ดูแล เพิ่มสินค้า แก้ไขราคา และอัปโหลดรูป SQL สร้างฐานข้อมูลต้องรันใน Supabase แยกต่างหาก Cloudflare ไม่รันไฟล์ SQL นี้ให้ และข้อมูลสาธิตใน localStorage จะไม่ย้ายไปฐานข้อมูลจริง

เมื่อเชื่อม Git integration แล้ว การ push commit ใหม่ไป main จะเรียก build และ deploy อัตโนมัติ

อ้างอิง: [Deploy Vue on Cloudflare Pages](https://developers.cloudflare.com/pages/framework-guides/deploy-a-vue-site/), [Cloudflare build image](https://developers.cloudflare.com/pages/configuration/build-image/), [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Storage access control](https://supabase.com/docs/guides/storage/security/access-control)
"# Market" 
