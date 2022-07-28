//
//  ImageViewController.swift
//  Picterest
//
//  Created by 백유정 on 2022/07/25.
//

import UIKit
import CoreData

protocol CustomLayoutDelegate: AnyObject {
  func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat
}

class ImageViewController: UIViewController {
    
    private var imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return cv
    }()
    private var viewModel = ImageViewModel()
    var photoList: [Photo] = []
    private var startPage = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        attribute()
        layout()
        bind(viewModel)
        fetchPhoto()
    }
}

extension ImageViewController {
    
    private func attribute() {
        imageCollectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.identifier)
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        imageCollectionView.prefetchDataSource = self
        
        let customLayout = ImageColletionViewCustomLayout()
        customLayout.delegate = self
        imageCollectionView.collectionViewLayout = customLayout
    }
    
    private func layout() {
        [
            imageCollectionView
        ].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            imageCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            imageCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func bind(_ viewModel: ImageViewModel) {
        self.viewModel = viewModel
    }
    
    private func fetchPhoto() {
        print("fetchPhoto", startPage)
        
        viewModel.getRandomPhoto(startPage) { [weak self] result in
            guard let self = self  else { return }
            switch result {
            case .success(let photos):
                self.photoList += photos
                photos.forEach { photo in
                    print(photo.id)
                }
                DispatchQueue.main.async {
                    self.imageCollectionView.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

extension ImageViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = imageCollectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.identifier, for: indexPath) as? ImageCollectionViewCell else { return UICollectionViewCell() }
        
        var isStarButtonSelected: Bool = false
        if CoreDataManager.shared.searchSavePhoto(photoList[indexPath.row].id) != nil {
            isStarButtonSelected = true
        }
        cell.fetchData(photoList[indexPath.row], indexPath, isStarButtonSelected)
        cell.delegate = self
        
        return cell
    }
}

extension ImageViewController: CustomLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        let width: CGFloat = (view.bounds.width - 4) / 2
        let ratio: Double = photoList[indexPath.row].height / photoList[indexPath.row].width
        
        return CGFloat(width * ratio)
    }
}

extension ImageViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if photoList.count - 1 == indexPath.row {
                startPage += 1
                fetchPhoto()
            }
        }
    }
}

extension ImageViewController: SavePhotoImageDelegate {
    
    func tapStarButton(sender: UIButton, indexPath: IndexPath) {
        
        let id = photoList[indexPath.row].id
        var text: String!
        let originUrl = photoList[indexPath.row].urls.small
        let ratio = photoList[indexPath.row].height / photoList[indexPath.row].width
        
        if sender.isSelected {
            // 저장
            let alert = UIAlertController(title: "사진 저장", message: "저장할 메시지", preferredStyle: .alert)
            let ok = UIAlertAction(title: "저장", style: .default) { ok in
                let location = PhotoFileManager.shared.createPhotoFile(self.viewModel.loadImage(originUrl), id).absoluteString
                text = alert.textFields?[0].text
                CoreDataManager.shared.createSavePhoto(id, text, originUrl, location, ratio)
            }
            alert.addTextField()
            alert.addAction(ok)
            self.present(alert, animated: true)
        } else {
            // 지우기
            
        }
    }
}
