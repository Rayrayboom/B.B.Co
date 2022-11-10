//
//  CoAccountingViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/9.
//

import UIKit
import FirebaseFirestore

// WARNING: Change these constants according to your project's design
private struct Const {
    /// Image height/width for Large NavBar state
    static let ImageSizeForLargeState: CGFloat = 40
    /// Margin from right anchor of safe area to right anchor of Image
    static let ImageRightMargin: CGFloat = 16
    /// Margin from bottom anchor of NavBar to bottom anchor of Image for Large NavBar state
    static let ImageBottomMarginForLargeState: CGFloat = 12
    /// Margin from bottom anchor of NavBar to bottom anchor of Image for Small NavBar state
    static let ImageBottomMarginForSmallState: CGFloat = 6
    /// Image height/width for Small NavBar state
    static let ImageSizeForSmallState: CGFloat = 32
    /// Height of NavBar for Small state. Usually it's just 44
    static let NavBarHeightSmallState: CGFloat = 44
    /// Height of NavBar for Large state. Usually it's just 96.5 but if you have a custom font for the title, please make sure to edit this value since it changes the height for Large state of NavBar
    static let NavBarHeightLargeState: CGFloat = 96.5
}

class CoAccountingViewController: UIViewController {
    private let imageView = UIImageView(image: UIImage(systemName: "plus"))
    // 用來存所選日期的data
    var data: [Account] = [] {
        didSet {
            self.bookTableView.reloadData()
        }
    }

    @IBOutlet weak var bookTableView: UITableView!
    @IBAction func addDetail(_ sender: UIButton) {
        guard let presentCoDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "addCoDetailVC") as? AddCoDetailViewController else {
            fatalError("error")
        }

        presentCoDetailVC.modalPresentationStyle = .fullScreen
        present(presentCoDetailVC, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bookTableView.delegate = self
        bookTableView.dataSource = self
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchCoAccount(subCollection: "co_expenditure")
        bookTableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showImage(false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showImage(true)
    }

    // 從Firebase上fetch共同帳本資料
    func fetchCoAccount(subCollection: String) {
        data = []
        let dataBase = Firestore.firestore()
        dataBase.collection("co-account/U5nzbfkDyHNIXAvVUdZD/\(subCollection)")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                self.data.append(contentsOf: account)
                print("category here \(self.data)")
            }
    }

    // 從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(subCollection: String, indexPathRow: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("co-account").document("U5nzbfkDyHNIXAvVUdZD").collection(subCollection).document(data[indexPathRow].id)
        documentRef.delete()
    }

    /// Show or hide the image from NavBar while going to next screen or back to initial screen
    ///
    /// - Parameter show: show or hide the image from NavBar
    private func showImage(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.imageView.alpha = show ? 1.0 : 0.0
        }
    }

//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard let height = navigationController?.navigationBar.frame.height else { return }
//        moveAndResizeImage(for: height)
//    }

    private func setupUI() {
        navigationController?.navigationBar.prefersLargeTitles = true

        title = "Large Title"

        // Initial setup for image for Large NavBar state since the the screen always has Large NavBar once it gets opened
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(imageView)
        imageView.layer.cornerRadius = Const.ImageSizeForLargeState / 2
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.rightAnchor.constraint(equalTo: navigationBar.rightAnchor, constant: -Const.ImageRightMargin),
            imageView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -Const.ImageBottomMarginForLargeState),
            imageView.heightAnchor.constraint(equalToConstant: Const.ImageSizeForLargeState),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
            ])
    }

    private func moveAndResizeImage(for height: CGFloat) {
        let coeff: CGFloat = {
            let delta = height - Const.NavBarHeightSmallState
            let heightDifferenceBetweenStates = (Const.NavBarHeightLargeState - Const.NavBarHeightSmallState)
            return delta / heightDifferenceBetweenStates
        }()

        let factor = Const.ImageSizeForSmallState / Const.ImageSizeForLargeState

        let scale: CGFloat = {
            let sizeAddendumFactor = coeff * (1.0 - factor)
            return min(1.0, sizeAddendumFactor + factor)
        }()

        // Value of difference between icons for large and small states
        let sizeDiff = Const.ImageSizeForLargeState * (1.0 - factor) // 8.0
        let yTranslation: CGFloat = {
            /// This value = 14. It equals to difference of 12 and 6 (bottom margin for large and small states). Also it adds 8.0 (size difference when the image gets smaller size)
            let maxYTranslation = Const.ImageBottomMarginForLargeState - Const.ImageBottomMarginForSmallState + sizeDiff
            return max(0, min(maxYTranslation, (maxYTranslation - coeff * (Const.ImageBottomMarginForSmallState + sizeDiff))))
        }()

        let xTranslation = max(0, sizeDiff - coeff * sizeDiff)

        imageView.transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: xTranslation, y: yTranslation)
    }
}

extension CoAccountingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
    }
}

extension CoAccountingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let listCell = tableView.dequeueReusableCell(withIdentifier: "listCell") as? ListTableViewCell else {
            fatalError("can not create listCell")
        }

        listCell.titleLabel.text = data[indexPath.row].category
        listCell.dateLabel.text = data[indexPath.row].date
        listCell.userLabel.text = data[indexPath.row].user
        listCell.categoryImage.image = UIImage(systemName: "hand.thumbsup.fill")

        return listCell
    }

    // tableView右滑刪除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            // 順序問題，需要先偵測對應indexPath資料再進行刪除
            deleteSpecificData(subCollection: "co_expenditure", indexPathRow: indexPath.row)
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
