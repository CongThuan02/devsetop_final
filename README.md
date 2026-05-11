# devsetop_final

A new Flutter project.

## Deploy web len Firebase Hosting

Project dung FVM va pin Flutter version trong `.fvmrc`. Workflow `.github/workflows/deploy.yml` se tu dong cai FVM, cai dung Flutter version, build Flutter web va deploy len Firebase Hosting khi co code duoc push len nhanh `main`.

Truoc khi push, tao cac GitHub Secrets trong repo:

- `FIREBASE_PROJECT_ID`: Firebase project ID, vi du `pwmgr-devsecops`
- `FIREBASE_SERVICE_ACCOUNT`: noi dung JSON cua service account co quyen deploy Firebase Hosting
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_WEB_API_KEY`
- `FIREBASE_WEB_APP_ID`

Service account nen co quyen `Firebase Hosting Admin` tren Firebase/GCP project. Sau khi merge hoac push len `main`, vao tab `Actions` cua GitHub va mo workflow `Deploy Web to Firebase` de xem log deploy.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
