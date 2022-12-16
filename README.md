# B.B.Co

<p align="middle">
  <image src="https://user-images.githubusercontent.com/108859236/207882248-8f106069-6b2c-42e1-a8ff-da1f0e39bdd0.jpg" width="220"/>
</p>

<p align="middle">
An accounting App combines the electronic invoice QR Code scanner, shared expenses, and personal monthly
overview.<br>
Build a good habit of tracking your daily spending.
</p>
  
<p align="middle">
    <a href="https://apps.apple.com/app/b-b-co/id6444242872"><img src="https://i.imgur.com/NKyvGNy.png" width="120"/></a>
</p>

<p align="middle">
  <img src="https://img.shields.io/badge/platform-iOS-lightgray%22%3E"> <img src="https://img.shields.io/badge/release-v1.1.0-green%22%3E">
</p>

## Features


#### Home

* You can see the calendar that hasn't been added record yet; it would have the expenditure, revenue, or money transfer information when you added.

<image src="https://user-images.githubusercontent.com/108859236/207876705-6ea454e7-91fa-42cb-a057-aaba07be755d.png" width="220"/><image src="https://user-images.githubusercontent.com/108859236/207876720-53322b08-8fd1-4aaa-a149-33b64a28bfef.png" width="220"/>

#### Side menu

* User account setting includes sign-out and account deletion. You can also adjust the subcategory list here.

<image src="https://user-images.githubusercontent.com/108859236/207876678-0f8abbb6-e8a3-4b6b-ae4c-ba0c33961d7e.png" width="220"/>

#### Add your daily records

* B.B.Co provides three kinds of categories, "expenditure," "revenue," and "money transfer" mode.
* Choose one of these categories and add the information you want to record.
* You can also create customized subcategories for your demand.

<image src="https://user-images.githubusercontent.com/108859236/207876345-1320c513-e135-436e-b993-fe61df9d1e80.png" width="220"/><image src="https://user-images.githubusercontent.com/108859236/207876530-2a733c3e-4b50-4a5c-b862-b317f01eafaa.png" width="220"/>

#### E-invoice QR code scanner

* If you want to record your account quickly, you can use the QR code scanner to input e-invoice detail automatically.

<image src="https://user-images.githubusercontent.com/108859236/207876971-56bd1d9e-fddd-4857-90f3-1632269f9615.png" width="220"/>

#### Monthly overview

* B.B.Co provides expenditure and revenue to show monthly overviews. You can change different months by using the calendar.

<image src="https://user-images.githubusercontent.com/108859236/207877112-0b10371b-c979-49a6-a588-d08d123899bd.png" width="220"/><image src="https://user-images.githubusercontent.com/108859236/207877053-9d2e2fc1-92e8-4ba8-9254-689d805f8389.png" width="220"/>

#### Share expenses

* It can be used for trips, couple financing, roommates, or other sharing events.
* All accounting book members have their expenditure data and can invite more members into the group independently.

<image src="https://user-images.githubusercontent.com/108859236/207877783-1bab8b4d-b0a7-4ba4-bc82-3013596b367c.png" width="220"/><image src="https://user-images.githubusercontent.com/108859236/207877727-ae4227e4-578a-4d9c-8543-cdd1589e025c.png" width="220"/>
<image src="https://user-images.githubusercontent.com/108859236/207877826-0f3d9054-4157-4880-ac1a-d56edea40407.png" width="220"/><image src="https://user-images.githubusercontent.com/108859236/207877812-9f153b8f-593e-4e47-8928-8633183b7fcd.png" width="220"/>

## Technical Hightlights

* Developed with **Firebase Firestore** for users can instantly record and update the expenses.
* Applied **AVCaptureSession** from **AVFoundation** to fulfill the QR Code automatic scanning function.
* Obtained **Ministry of Finance's electronic invoice API** resources through multiple reviews and approval stages by the government.
* Integrated **Sign in with Apple** into the login process, stored authentication tokens and sensitive
information into **Keychain** to enhance users’ security and privacy.
* Synced user data across devices by verifying user’s identity with token.
* Implemented a **customized calculator** to enhance user experience in inputting daily records.
* Used **Dispatch Group** to fetch multiple data synchronously before updated UI.
* Applied **Unit Test** to verify the correctness of the electronic invoice decode data.


## Libraries
	
* Firebase SDK
* IQKeyboardManagerSwift
* SwiftKeychainWrapper
* SwiftJWT
* AVFoundation
* JGProgressHUD
* Charts
* SideMenu
* SPAlert
* lottie-ios
* Tracking Tool
    * FirebaseCrashlytics
    

## Version
> 1.1.0


## Release Notes
| Version       | Date          | Note          |
| ------------- |:-------------:| ------------- |
| 1.0.0         | 2022/12/01    | First released on App Store. |
| 1.1.0      | 2022/12/08    | Added new features and optimized UI. |
    

## Requirement

* iOS 15.0+
* Xcode 13.4.1+

## Contacts

Yu Jui Chang

Mail: rayrayboom@hotmail.com.tw

## License

This project is licensed under the terms of the MIT [License](https://github.com/Rayrayboom/B.B.Co/blob/readme_license/LICENSE).
