# টেস্ট (Test) — Windows Desktop UI Test Workflow

এই ফোল্ডারে রাখা আছে Windows অ্যাপ্লিকেশনের **অটোমেটেড UI টেস্ট ওয়ার্কফ্লো**।

**ফাইল:** [`windows-desktop-ui-test.yml`](./windows-desktop-ui-test.yml)
(ক্যাননিকাল কপি — GitHub শুধু `.github/workflows/`-এর ভেতরের ফাইল চালায়, তাই
একই কোড `.github/workflows/windows-desktop-ui-test.yml`-এ বসানো আছে।)

## ওয়ার্কফ্লোটি যা করে (ধাপে ধাপে)

1. **বিল্ট Windows অ্যাপ ডাউনলোড** — আগের "Desktop Build (Windows & Linux)"
   ওয়ার্কফ্লোর সফল রান থেকে `convo-desktop-windows-x64` আর্টিফ্যাক্টটি নামিয়ে আনে।
2. **অটোমেটিক ইনস্টল** — ZIP আনজিপ করে `convo_chat.exe` খুঁজে রান করে।
3. **ভিডিও রেকর্ড** — পুরো সেশনটি ffmpeg `gdigrab` দিয়ে রেকর্ড করে
   (`convo-desktop-session.mp4`)।
4. **ডেমো অ্যাকাউন্টে অটো-লগইন** — রিপো secret `DEMO_EMAIL` / `DEMO_PASS`
   (লগইন পেজে SendKeys দিয়ে টাইপ + ENTER)।
5. **কয়েকটা স্ক্রিনশট** — প্রতিটি ধাপে: `01-app-launched`,
   `02-login-email-typed`, `03-login-password-typed`, `04-after-login`,
   `05-home-second-view`।
6. **এক ফোল্ডারে সব** — সব স্ক্রিনশট + ভিডিও `test-results/desktop-ui/`-তে,
   আর সেটাই আপলোড হয় **একটাই** আর্টিফ্যাক্ট: `convo-windows-ui-evidence`।

## চালানো (Run)

- **অটো**: "Desktop Build (Windows & Linux)" সফল হলেই এটি নিজে ট্রিগার হয়
  (`workflow_run`)।
- **ম্যানুয়াল**: GitHub → Actions → "Windows Desktop UI Test" → Run workflow,
  অথবা:

```bash
gh workflow run windows-desktop-ui-test.yml --ref <branch>
```

রান শেষ হলে Actions রান পেজ থেকে `convo-windows-ui-evidence` আর্টিফ্যাক্টটি
ডাউনলোড করলেই ভিডিও ও সব স্ক্রিনশট একসাথে পাবেন।

## ক্রেডেনশিয়াল

ডেমো অ্যাকাউন্টের ইমেইল/পাসওয়ার্ড কোডে হার্ডকোড করা নেই —
রিপো **secrets** হিসেবে সংরক্ষিত:

```bash
gh secret set DEMO_EMAIL  -R mr44253990-del/convo-chat-all
gh secret set DEMO_PASS  -R mr44253990-del/convo-chat-all
```

দুটোই না থাকলে ওয়ার্কফ্লো প্রথম ধাপেই স্পষ্ট error দিয়ে থামবে।
