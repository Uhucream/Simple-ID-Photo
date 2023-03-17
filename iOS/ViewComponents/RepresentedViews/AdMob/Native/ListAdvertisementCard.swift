//
//  ListAdvertisementCard.swift
//  Simple ID Photo (iOS)
//  
//  Created by TakashiUshikoshi on 2023/03/17
//  
//

import SwiftUI
import GoogleMobileAds

struct ListAdvertisementCard: UIViewRepresentable {
    
    @Binding var nativeAd: GADNativeAd
    
    func makeUIView(context: Context) -> UIView {
        
        let containerView: UIView = .init()
        
        let nativeAdViewFromXIB: GADNativeAdView = Bundle.main.loadNibNamed(
            "ListAdvertisementCard",
            owner: nil
        )?.first as! GADNativeAdView
        
        nativeAdViewFromXIB.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.setContentHuggingPriority(.required, for: .horizontal)
        containerView.setContentHuggingPriority(.required, for: .vertical)
        
        containerView.addSubview(nativeAdViewFromXIB)
        
        NSLayoutConstraint.activate([
            nativeAdViewFromXIB.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            nativeAdViewFromXIB.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            nativeAdViewFromXIB.topAnchor.constraint(equalTo: containerView.topAnchor),
            nativeAdViewFromXIB.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        return containerView
    }
    
    func updateUIView(_ containerView: UIView, context: Context) {
        
        guard let nativeAdView = containerView.subviews.first as? GADNativeAdView else { return }
        
        nativeAdView.nativeAd = nativeAd
        
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        nativeAdView.mediaView?.isHidden = true
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        var ratingStarImage: UIImage? {
            guard let starRating = nativeAd.starRating?.doubleValue else { return nil }
            
            if starRating >= 5 {
                return UIImage(named: "stars_5")
            }
            
            if starRating >= 4.5 {
                return UIImage(named: "stars_4.5")
            }
            
            if starRating >= 4 {
                return UIImage(named: "stars_4")
            }
            
            if starRating >= 3.5 {
                return UIImage(named: "stars_3.5")
            }
            
            if starRating >= 3 {
                return UIImage(named: "stars_3")
            }
            
            if starRating >= 2.5 {
                return UIImage(named: "stars_2.5")
            }
            
            return nil
        }
        
        (nativeAdView.starRatingView as? UIImageView)?.image = ratingStarImage
        nativeAdView.starRatingView?.isHidden = nativeAd.starRating == nil
        
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        nativeAdView.storeView?.isHidden = nativeAd.store == nil
        
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
        
        // In order for the SDK to process touch events properly, user interaction should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
    }
}
