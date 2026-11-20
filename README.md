## Mission and Problem
I am focusing on unemployment in Somaliland/Somalia, a serious challenge for families, job seekers, and policy makers.
Many countries across Africa face similar challenges, so this project uses data from across the continent while focusing on the Horn of Africa.
It helps labour-market analysts and public planners estimate a country's unemployment rate when survey data is missing and plan employment programmes.

## Dataset
The WDI download requests all 54 African countries for 1991-2024. The cleaned dataset has 1,799 country-year rows; Seychelles has no unemployment-target observations in this period, so the required target-missing-row removal leaves 53 represented countries. It contains 13 numeric indicators, the categorical columns `country` and `sub_region`, and the target `unemployment_rate`.
Source: [World Bank World Development Indicators](https://databank.worldbank.org/source/world-development-indicators).

## Public Swagger UI link
https://africa-unemployment-api.onrender.com/docs

## YouTube video demo link
[Watch the video demo](https://youtu.be/abP2q3BGUak?si=NjUP6BwrXAs5Ma6n).

## How to run the mobile app
1. Install [Flutter](https://docs.flutter.dev/get-started/install). For Android, also install Android Studio. For iOS, use a Mac with Xcode.
2. Download or clone this repository, then open a terminal in the repository folder.
3. Start an Android/iOS emulator or connect a phone. (iOS builds require macOS and Xcode.)
4. Open `summative/FlutterApp/lib/main.dart` and check that `apiBaseUrl` points to the deployed API.
5. In the terminal, run `cd summative/FlutterApp`, then run `flutter pub get`.
6. Run `flutter devices` to find your device ID, then run `flutter run -d <device-id>`.
7. Enter the indicator values and a country, then tap **Predict** to see the estimate.
