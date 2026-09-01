# 📱 Quản Lý Khách Hàng (iOS App + Cloudflare KV)

Ứng dụng quản lý khách hàng viết bằng **SwiftUI (iOS)** kết hợp **Cloudflare Worker + KV Storage** để lưu trữ đám mây tốc độ cao, miễn phí và an toàn.

---

## 🌟 Tính Năng Chính
- 👤 **Mục 1:** Tên khách hàng (tùy chọn)
- 💬 **Mục 2:** Zalo / Facebook (*Bắt buộc*)
- 🪪 **Mục 3a:** Tài khoản (*Bắt buộc*)
- 🔒 **Mục 3b:** Mật khẩu (*Bắt buộc - có nút 👁️ hiện/ẩn bảo mật*)
- 📅 **Mục 4:** Thời hạn hết hạn (*Bắt buộc - tự tính số ngày còn lại & cảnh báo 🟢🟡🔴*)
- 📝 **Mục 5:** Ghi chú (tùy chọn)
- ☁️ **Lưu trữ Cloud:** Cloudflare Workers KV (kèm bộ nhớ đệm Offline `UserDefaults`)
- 🎨 **Giao diện:** Sáng (Light Theme) sang trọng, chuẩn iOS 17+.

---

## 🚀 Bước 1: Thiết Lập Cloudflare Worker + KV (Miễn phí)

### Cách A: Qua giao diện Web Cloudflare Dashboard
1. Đăng nhập [dash.cloudflare.com](https://dash.cloudflare.com)
2. Vào mục **Workers & Pages** ➜ **KV** ➜ Nhấn **Create a Namespace** ➜ Đặt tên là `CUSTOMERS`.
3. Vào **Workers & Pages** ➜ **Create application** ➜ **Create Worker** ➜ Đặt tên `customer-manager-api`.
4. Nhấn **Settings** của Worker ➜ **Variables** ➜ **KV Namespace Bindings** ➜ **Add binding**:
   - **Variable name:** `KV`
   - **KV namespace:** chọn `CUSTOMERS` vừa tạo.
5. Nhấn **Edit code** ➜ Copy toàn bộ nội dung file [`cloudflare-worker/worker.js`](file:///c:/Users/webho/Downloads/Quản%20Lý/CustomerManager/cloudflare-worker/worker.js) dán vào ➜ Nhấn **Deploy**.
6. Copy URL Worker vừa tạo (ví dụ: `https://customer-manager-api.xxx.workers.dev`).

### Cách B: Bằng lệnh Terminal (Wrangler CLI)
```bash
cd cloudflare-worker
npx wrangler login
npx wrangler kv:namespace create CUSTOMERS
# Copy KV id vào file wrangler.toml
npx wrangler deploy
```

---

## 🔗 Bước 2: Cập Nhật URL Worker Vào App iOS

Mở file [`Sources/CustomerManager/Config.swift`](file:///c:/Users/webho/Downloads/Quản%20Lý/CustomerManager/Sources/CustomerManager/Config.swift) và thay thế URL của bạn:
```swift
enum Config {
    static let workerURL = "https://customer-manager-api.YOUR_SUBDOMAIN.workers.dev"
}
```

---

## 📦 Bước 3: Tự Động Build Thành File `.ipa` Bằng GitHub Actions

1. Khởi tạo Git và đẩy lên GitHub:
   ```bash
   git init
   git add .
   git commit -m "feat: iOS Customer Manager with Cloudflare KV & Light theme"
   git branch -M main
   git remote add origin https://github.com/TÊN_GITHUB_CỦA_BẠN/CustomerManager.git
   git push -u origin main
   ```
2. Vào repo trên GitHub ➜ Tab **Actions** ➜ Chọn **Build iOS App (IPA)** ➜ Nhấn **Run workflow**.
3. Sau khi build xong (khoảng 3-5 phút), tải file `.ipa` tại mục **Artifacts** ở cuối trang build.

---

## 📲 Cài Đặt IPA Lên iPhone (Miễn Phí)
- Sử dụng **[Sideloadly](https://sideloadly.io)** hoặc **[AltStore](https://altstore.io)** trên máy tính.
- Cắm cáp iPhone vào máy tính, kéo thả file `.ipa` vào Sideloadly, nhập Apple ID để cài đặt trực tiếp vào iPhone.
