//
//  PrivacyViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/26.
//
// swiftlint:disable line_length

import UIKit

class PrivacyViewController: UIViewController {
    @IBOutlet weak var privacyTextView: UITextView!
    @IBOutlet weak var dismissProvactBO: UIButton!
    @IBAction func closePrivacy(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        privacyTextView.backgroundColor =  UIColor().hexStringToUIColor(hex: "f2f6f7")
        dismissProvactBO.setTitle("關閉", for: .normal)
        dismissProvactBO.layer.cornerRadius = 10
        privacyTextView.text = """
        感謝您使用 B.B.Co！在您開始使用本軟體後，即表示您已閱讀並同意下述所有使用條款；若您不同意，請自行關閉並移除本軟體，謝謝。
        免責聲明：本軟體所載資料的準確性、可用性、完整性或效用，概不作明確或暗示的保證及聲明，對於使用本軟體而可能直接或間接導致的任何損失、損壞或傷害，本軟體之開發者不負任何法律承擔和責任。
        我們在此說明當您使用我們的軟體及服務時，我們是如何收集、使用及處理您的個人資料，請您詳閱下列內容以保障您的權益：
        一、隱私權保護政策的適用範圍
        隱私權保護政策內容，包括本服務如何處理在您使用服務時收集到的個人識別資料。隱私權保護政策不適用於本服務以外的相關連結網站，也不適用於非本服務所委託或參與管理的人員。

        二、個人資料的蒐集、處理及利用方式
        * 當您造訪本產品或使用本產品所提供之功能服務時，我們將視該功能性質，請您提供必要的個人資料，並在該特定目的範圍內處理及利用您的個人資料；非經您書面同意，本產品不會將個人資料用於其他用途。
        * 因本產品有提供掃描電子發票之功能，使用者可以自行決定是否使用該功能，電子發票蒐集及依法定義務進行個人資料之蒐集處理及利用，本產品將依法確保使用者之個人資料及權益之保護，謹遵守中華民國「個人資料保護法」之規範，本產品在取得發票消費內容後僅自動帶入對應輸入區域，我們不會主動搜集您的資料，請放心使用。
        * 基於優化本產品體驗之目的，我們有透過第三方服務去蒐集您在使用本產品所遇到的當機情況，這些當機資料並不涵蓋您私人記帳資料，僅單純追蹤閃退時相關的Log。
        三、資料之保護
        * 如因業務需要有必要委託其他單位提供服務時，本服務亦會嚴格要求其遵守保密義務，並且採取必要檢查程序以確定其將確實遵守。
        四、隱私權政策之修正
        本產品隱私權政策將因應需求隨時進行修正，修正後的條款將刊登於 APP 上，建議您定期查看以了解更新後的內容。
        五、聯繫我們
        如果您對於隱私權政策有任何疑問或建議，請隨時來信至 rayrayboom@hotmail.com.tw 與我們聯繫。
        
        Privacy Policy
        Last updated: November 25, 2022

        This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service and tells You about Your privacy rights and how the law protects You.

        We use Your Personal data to provide and improve the Service. By using the Service, You agree to the collection and use of information in accordance with this Privacy Policy. This Privacy Policy has been created with the help of the Privacy Policy Generator.

        Interpretation and Definitions
        Interpretation

        The words of which the initial letter is capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.

        Definitions

        For the purposes of this Privacy Policy:

        Account means a unique account created for You to access our Service or parts of our Service.

        Affiliate means an entity that controls, is controlled by or is under common control with a party, where "control" means ownership of 50% or more of the shares, equity interest or other securities entitled to vote for election of directors or other managing authority.

        Application means the software program provided by the Company downloaded by You on any electronic device, named B.B.Co

        Company (referred to as either "the Company", "We", "Us" or "Our" in this Agreement) refers to B.B.Co.

        Country refers to: Taiwan

        Device means any device that can access the Service such as a computer, a cellphone or a digital tablet.

        Personal Data is any information that relates to an identified or identifiable individual.

        Service refers to the Application.

        Service Provider means any natural or legal person who processes the data on behalf of the Company. It refers to third-party companies or individuals employed by the Company to facilitate the Service, to provide the Service on behalf of the Company, to perform services related to the Service or to assist the Company in analyzing how the Service is used.

        Usage Data refers to data collected automatically, either generated by the use of the Service or from the Service infrastructure itself (for example, the duration of a page visit).

        You means the individual accessing or using the Service, or the company, or other legal entity on behalf of which such individual is accessing or using the Service, as applicable.

        Collecting and Using Your Personal Data
        Types of Data Collected

        Personal Data

        While using Our Service, We may ask You to provide Us with certain personally identifiable information that can be used to contact or identify You. Personally identifiable information may include, but is not limited to:

        Email address

        First name and last name

        Usage Data

        Usage Data

        Usage Data is collected automatically when using the Service.

        Usage Data may include information such as Your Device's Internet Protocol address (e.g. IP address), browser type, browser version, the pages of our Service that You visit, the time and date of Your visit, the time spent on those pages, unique device identifiers and other diagnostic data.

        When You access the Service by or through a mobile device, We may collect certain information automatically, including, but not limited to, the type of mobile device You use, Your mobile device unique ID, the IP address of Your mobile device, Your mobile operating system, the type of mobile Internet browser You use, unique device identifiers and other diagnostic data.

        We may also collect information that Your browser sends whenever You visit our Service or when You access the Service by or through a mobile device.

        Use of Your Personal Data

        The Company may use Personal Data for the following purposes:

        To provide and maintain our Service, including to monitor the usage of our Service.

        To manage Your Account: to manage Your registration as a user of the Service. The Personal Data You provide can give You access to different functionalities of the Service that are available to You as a registered user.

        For the performance of a contract: the development, compliance and undertaking of the purchase contract for the products, items or services You have purchased or of any other contract with Us through the Service.

        To contact You: To contact You by email, telephone calls, SMS, or other equivalent forms of electronic communication, such as a mobile application's push notifications regarding updates or informative communications related to the functionalities, products or contracted services, including the security updates, when necessary or reasonable for their implementation.

        To provide You with news, special offers and general information about other goods, services and events which we offer that are similar to those that you have already purchased or enquired about unless You have opted not to receive such information.

        To manage Your requests: To attend and manage Your requests to Us.

        For business transfers: We may use Your information to evaluate or conduct a merger, divestiture, restructuring, reorganization, dissolution, or other sale or transfer of some or all of Our assets, whether as a going concern or as part of bankruptcy, liquidation, or similar proceeding, in which Personal Data held by Us about our Service users is among the assets transferred.

        For other purposes: We may use Your information for other purposes, such as data analysis, identifying usage trends, determining the effectiveness of our promotional campaigns and to evaluate and improve our Service, products, services, marketing and your experience.

        We may share Your personal information in the following situations:

        With Service Providers: We may share Your personal information with Service Providers to monitor and analyze the use of our Service, to contact You.
        For business transfers: We may share or transfer Your personal information in connection with, or during negotiations of, any merger, sale of Company assets, financing, or acquisition of all or a portion of Our business to another company.
        With Affiliates: We may share Your information with Our affiliates, in which case we will require those affiliates to honor this Privacy Policy. Affiliates include Our parent company and any other subsidiaries, joint venture partners or other companies that We control or that are under common control with Us.
        With business partners: We may share Your information with Our business partners to offer You certain products, services or promotions.
        With other users: when You share personal information or otherwise interact in the public areas with other users, such information may be viewed by all users and may be publicly distributed outside.
        With Your consent: We may disclose Your personal information for any other purpose with Your consent.
        Retention of Your Personal Data

        The Company will retain Your Personal Data only for as long as is necessary for the purposes set out in this Privacy Policy. We will retain and use Your Personal Data to the extent necessary to comply with our legal obligations (for example, if we are required to retain your data to comply with applicable laws), resolve disputes, and enforce our legal agreements and policies.

        The Company will also retain Usage Data for internal analysis purposes. Usage Data is generally retained for a shorter period of time, except when this data is used to strengthen the security or to improve the functionality of Our Service, or We are legally obligated to retain this data for longer time periods.

        Transfer of Your Personal Data

        Your information, including Personal Data, is processed at the Company's operating offices and in any other places where the parties involved in the processing are located. It means that this information may be transferred to — and maintained on — computers located outside of Your state, province, country or other governmental jurisdiction where the data protection laws may differ than those from Your jurisdiction.

        Your consent to this Privacy Policy followed by Your submission of such information represents Your agreement to that transfer.

        The Company will take all steps reasonably necessary to ensure that Your data is treated securely and in accordance with this Privacy Policy and no transfer of Your Personal Data will take place to an organization or a country unless there are adequate controls in place including the security of Your data and other personal information.

        Delete Your Personal Data

        You have the right to delete or request that We assist in deleting the Personal Data that We have collected about You.

        Our Service may give You the ability to delete certain information about You from within the Service.

        You may update, amend, or delete Your information at any time by signing in to Your Account, if you have one, and visiting the account settings section that allows you to manage Your personal information. You may also contact Us to request access to, correct, or delete any personal information that You have provided to Us.

        Please note, however, that We may need to retain certain information when we have a legal obligation or lawful basis to do so.

        Disclosure of Your Personal Data

        Business Transactions

        If the Company is involved in a merger, acquisition or asset sale, Your Personal Data may be transferred. We will provide notice before Your Personal Data is transferred and becomes subject to a different Privacy Policy.

        Law enforcement

        Under certain circumstances, the Company may be required to disclose Your Personal Data if required to do so by law or in response to valid requests by public authorities (e.g. a court or a government agency).

        Other legal requirements

        The Company may disclose Your Personal Data in the good faith belief that such action is necessary to:

        Comply with a legal obligation
        Protect and defend the rights or property of the Company
        Prevent or investigate possible wrongdoing in connection with the Service
        Protect the personal safety of Users of the Service or the public
        Protect against legal liability
        Security of Your Personal Data

        The security of Your Personal Data is important to Us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure. While We strive to use commercially acceptable means to protect Your Personal Data, We cannot guarantee its absolute security.

        Children's Privacy
        Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13. If You are a parent or guardian and You are aware that Your child has provided Us with Personal Data, please contact Us. If We become aware that We have collected Personal Data from anyone under the age of 13 without verification of parental consent, We take steps to remove that information from Our servers.

        If We need to rely on consent as a legal basis for processing Your information and Your country requires consent from a parent, We may require Your parent's consent before We collect and use that information.

        Links to Other Websites
        Our Service may contain links to other websites that are not operated by Us. If You click on a third party link, You will be directed to that third party's site. We strongly advise You to review the Privacy Policy of every site You visit.

        We have no control over and assume no responsibility for the content, privacy policies or practices of any third party sites or services.

        Changes to this Privacy Policy
        We may update Our Privacy Policy from time to time. We will notify You of any changes by posting the new Privacy Policy on this page.

        We will let You know via email and/or a prominent notice on Our Service, prior to the change becoming effective and update the "Last updated" date at the top of this Privacy Policy.

        You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.

        Contact Us
        If you have any questions about this Privacy Policy, You can contact us:

        By email: rayrayboom@hotmail.com.tw
        """
    }
}
