#!/usr/bin/env bash
# Yazan Game OS - Quick GitHub Push Script
# هذا السكربت يساعدك على رفع المشروع إلى حسابك في GitHub بضغطة واحدة

echo "=================================================="
echo "    رفع نظام Yazan Game OS إلى مستودع GitHub     "
echo "=================================================="

if [ -z "$1" ]; then
    echo "الرجاء إدخال رابط مستودع GitHub الخاص بك:"
    echo "مثال: https://github.com/USERNAME/yazan-game-os.git"
    read -p "رابط المستودع (Repo URL): " REPO_URL
else
    REPO_URL=$1
fi

if [ -z "$REPO_URL" ]; then
    echo "لم يتم إدخال رابط، تم إلغاء العملية."
    exit 1
fi

echo "[*] جاري ضبط رابط المستودع..."
git remote remove origin 2>/dev/null
git remote add origin "$REPO_URL"
git branch -M main

echo "[*] جاري رفع الملفات إلى GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo "=================================================="
    echo "  [+] تم رفع المشروع بنجاح إلى GitHub!"
    echo "  [+] سيبدأ الآن بناء الـ ISO تلقائياً عبر GitHub Actions!"
    echo "  [+] تفقد تبويب Actions في مستودعك لتحميل yazan-game-os.iso"
    echo "=================================================="
else
    echo "[-] حدث خطأ أثناء الرفع، تأكد من صلاحيات الحساب أو الـ Token."
fi
