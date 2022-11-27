//
//  PreviewViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/27.
//
import UIKit
import SwiftKeychainWrapper
import Lottie


class PreviewViewController: UIViewController {
    
    @IBOutlet weak var previewScrollView: UIScrollView!
    @IBOutlet weak var previewPageControl: UIPageControl!
    @IBOutlet weak var animationViewFirst: LottieAnimationView!
    @IBOutlet weak var animationViewSecond: LottieAnimationView!
    @IBOutlet weak var animationViewThird: LottieAnimationView!
    @IBAction func goToSignIn(_ sender: UIButton) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let presentSignInVC = mainStoryboard
            .instantiateViewController(withIdentifier: "signInVC") as? SignInViewController
        else {
            fatalError("can not present privacyVC")
        }
        presentSignInVC.modalPresentationStyle = .fullScreen
        present(presentSignInVC, animated: true)
    }
    @IBAction func changePage(_ sender: UIPageControl) {
        let point = CGPoint(x: previewScrollView.bounds.width * CGFloat(sender.currentPage), y: 0)
        previewScrollView.setContentOffset(point, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        setupAnimation()
//        previewPageControl.tintColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
        animationViewFirst.loopMode = .loop
        animationViewFirst.contentMode = .scaleAspectFit
        animationViewFirst.clipsToBounds = true
        animationViewFirst.play()

        previewScrollView.delegate = self
        // 判斷如果使用者已經登入過，就直接導到首頁
        if (KeychainWrapper.standard.string(forKey: "id") != nil) {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
            UIApplication.shared.windows.first?.rootViewController = viewController
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }

    func setupAnimation() {
        let animationView: [LottieAnimationView?] = [animationViewFirst, animationViewSecond, animationViewThird]
        for animate in animationView {
            animate?.loopMode = .loop
            animate?.contentMode = .scaleAspectFit
            animate?.clipsToBounds = true
            animate?.play()
        }
    }
}

extension PreviewViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let animationView: [LottieAnimationView?] = [animationViewFirst, animationViewSecond, animationViewThird]

        previewPageControl.numberOfPages = animationView.count
        let page = previewScrollView.contentOffset.x / previewScrollView.bounds.width
        previewPageControl.currentPage = Int(page)

        for animate in animationView {
            animate?.stop()
        }

        switch previewPageControl.currentPage {
        case 0:
            animationView[0]?.loopMode = .loop
            animationView[0]?.contentMode = .scaleAspectFill
            animationView[0]?.clipsToBounds = true
            animationView[0]?.play()
        case 1:
            animationView[1]?.loopMode = .loop
            animationView[1]?.contentMode = .scaleAspectFill
            animationView[1]?.clipsToBounds = true
            animationView[1]?.play()
        default:
            animationView[2]?.loopMode = .loop
            animationView[2]?.contentMode = .scaleAspectFit
            animationView[2]?.clipsToBounds = true
            animationView[2]?.play()
        }
    }
}
