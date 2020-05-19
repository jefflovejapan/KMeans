//
//  ViewController.swift
//  KMeans
//
//  Created by Jeffrey Blagdon on 2020-05-19.
//  Copyright © 2020 polyergy. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController {
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: newLayout())
    let colorsView = UIStackView()
    let imageNames = ["ceiling", "couch", "yard", "moon"]
    lazy var imageURLs = getImageURLs()
    lazy var uiImages = getUIImages(from: imageURLs)
    lazy var ciImages = getCIImages(from: imageURLs)
    var visibleIndex = 0 {
        didSet {
            if visibleIndex != oldValue {
                recomputeColors(forImageAt: visibleIndex)
            }
        }
    }

    private func newLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: provideSection)
        layout.configuration.scrollDirection = .horizontal
        return layout
    }

    private func getImageURLs() -> [URL] {
        return imageNames.map { name -> URL in
            let url = Bundle.main.url(forResource: name, withExtension: "png")
            return url!
        }
    }

    private func getUIImages(from urls: [URL]) -> [UIImage] {
        let mgr = FileManager.default
        return urls.map { url -> UIImage in
            let data = mgr.contents(atPath: url.path)!
            return UIImage(data: data)!
        }
    }

    private func getCIImages(from urls: [URL]) -> [CIImage] {
        return urls.map { url -> CIImage in
            return CIImage(contentsOf: url)!
        }
    }

    private func recomputeColors(forImageAt index: Int) {
        for arrSubview in colorsView.arrangedSubviews {
            colorsView.removeArrangedSubview(arrSubview)
        }

        let ciImage = ciImages[index]

        let colors: [CIColor] = [
                        CIColor(color: .red),
//                                             CIColor(color: .blue),
//                                             CIColor(color: .green),
            //                                 CIColor(color: .cyan),
            //                                 CIColor(color: .magenta),
            //                                 CIColor(color: .yellow),
            //                                 CIColor(color: .black),
//            CIColor(color: .gray),
//            CIColor(color: .lightGray),
//            CIColor(color: .darkGray)
        ]

        let kMeansFilter = CIFilter(name: "CIKMeans", parameters: [
            "inputCount": 32,
            kCIInputExtentKey: ciImage.extent,
            kCIInputImageKey: ciImage,
            "inputMeans": colors,
            "inputPerceptual": true,
            "inputPasses": 10
        ])

        let outputImage = kMeansFilter!.outputImage!
        for i in 0 ..< Int(outputImage.extent.width) {
            let inputExtent = CIVector(cgRect: CGRect(x: CGFloat(i), y: 0, width: 1, height: 1))
            let sampledColor = CIFilter(name: "CIAreaAverage", parameters: [
                kCIInputImageKey: outputImage,
                kCIInputExtentKey: inputExtent
            ])
            let colorImg = sampledColor!.outputImage!
            let saturatedColor = CIFilter(name: "CIColorControls", parameters: [
                kCIInputImageKey: colorImg,
                kCIInputSaturationKey: 5.0
            ])
            let imageView = UIImageView(image: UIImage(ciImage: saturatedColor!.outputImage!))
            //            imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            //            imageView.translatesAutoresizingMaskIntoConstraints = false
            colorsView.addArrangedSubview(imageView)
        }
    }

    func provideSection(at index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let fullHeightAndWidth = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: fullHeightAndWidth)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: fullHeightAndWidth, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered

        section.visibleItemsInvalidationHandler = handleVisibleItemsInvalidation(for:at:environment:)
        return section
    }

    func handleVisibleItemsInvalidation(for items: [NSCollectionLayoutVisibleItem], at point: CGPoint, environment: NSCollectionLayoutEnvironment) {
        if let newIndex = items.first(where: { $0.frame.contains(point) })?.indexPath.item {
            self.visibleIndex = newIndex
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
        colorsView.axis = .horizontal
        colorsView.alignment = .fill
        colorsView.distribution = .fillEqually

        for imgView in [collectionView, colorsView] {
            imgView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imgView)
            imgView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            imgView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        }

        collectionView.contentMode = .scaleAspectFit
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        colorsView.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
        colorsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        colorsView.heightAnchor.constraint(equalTo: collectionView.heightAnchor).isActive = true
        collectionView.delegate = self
        collectionView.dataSource = self
        recomputeColors(forImageAt: 0)
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uiImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath) as! ImageCell
        cell.imageView.image = uiImages[indexPath.item]
        return cell
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("ended animation")
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("ended decelerating")
    }
}

class ImageCell: UICollectionViewCell {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
