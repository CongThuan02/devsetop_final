# devsetop_final

A new Flutter project.

## Deploy web len Firebase Hosting

Project dung FVM va pin Flutter version trong `.fvmrc`. Workflow `.github/workflows/deploy.yml` se tu dong cai FVM, cai dung Flutter version, build Flutter web va deploy len Firebase Hosting khi co code duoc push len nhanh `main`.

Truoc khi push, tao mot trong hai GitHub Secrets trong repo:

- `FIREBASE_SERVICE_ACCOUNT`: noi dung JSON cua service account co quyen deploy Firebase Hosting
- `FIREBASE_SERVICE_ACCOUNT_PWMGR_DEVSECOPS`: ten secret Firebase CLI thuong tao khi chay `firebase init hosting:github`

Firebase client config da nam trong `lib/firebase_options.dart`, nen workflow khong can GitHub Variables cho `FIREBASE_PROJECT_ID`, `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, ... nua. Service account nen co quyen `Firebase Hosting Admin` tren Firebase/GCP project. Sau khi merge hoac push len `main`, vao tab `Actions` cua GitHub va mo workflow `Deploy Web to Firebase` de xem log deploy.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
