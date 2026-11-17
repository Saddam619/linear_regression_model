## Mission and Problem
Predict national unemployment rates across Africa, with an East Africa focus, from World Bank indicators.
A labour-market analyst or ministry planner can estimate rates when survey data is missing and target job-creation programmes.

## Dataset
The WDI download requests all 54 African countries for 1991-2024. The cleaned dataset has 1,799 country-year rows; Seychelles has no unemployment-target observations in this period, so the required target-missing-row removal leaves 53 represented countries. It contains 13 numeric indicators, the categorical columns `country` and `sub_region`, and the target `unemployment_rate`.
Source: [World Bank World Development Indicators](https://databank.worldbank.org/source/world-development-indicators).

## Public Swagger UI link
https://africa-unemployment-api.onrender.com/docs

## YouTube video demo link
(Placeholder: add the YouTube demo URL.)

## How to run the mobile app
1. Install [Flutter](https://docs.flutter.dev/get-started/install) and Android Studio.
2. Start an Android emulator or connect an Android phone.
3. In a terminal, run `cd summative/FlutterApp`.
4. Set `apiBaseUrl` in `lib/main.dart` to your deployed service address.
5. Run `flutter pub get`.
6. Run `flutter run -d <device id>`.
7. Enter the indicator values and a country, then tap **Predict**.
