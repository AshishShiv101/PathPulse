//
//  AccountPage.swift
//  Programatic-UI
//
//  Created by Anurag on 09/11/24.
//

import UIKit

class AccountPage: UIViewController {
    private let scrollView = UIScrollView()
    private let profileImageView = UIImageView()
       private let nameLabel = UILabel()
       private let phoneLabel = UILabel()
       
       private let privacyButton = UIButton()
       private let editContactsButton = UIButton()
       private let logoutButton = UIButton()
       private let editProfileButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
           view.backgroundColor = UIColor(hex: "#222222")
           setupNavigationBar()
           setupProfileImageView()
           setupLabels()
           setupButtons()

    }
    

  
    private func setupNavigationBar() {
           navigationItem.title = "Account"
           navigationController?.navigationBar.prefersLargeTitles = false
           navigationItem.hidesBackButton = true
       }
       
       private func setupProfileImageView() {
           profileImageView.image = UIImage(named: "cbum")
           profileImageView.contentMode = .scaleAspectFill
           profileImageView.layer.cornerRadius = 50
           profileImageView.layer.masksToBounds = true
           profileImageView.layer.borderWidth = 2
           profileImageView.layer.borderColor = UIColor(hex: "#40CBD8").cgColor
           profileImageView.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(profileImageView)
           
           // Adding shadow
           profileImageView.layer.shadowColor = UIColor.black.cgColor
           profileImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
           profileImageView.layer.shadowOpacity = 0.3
           profileImageView.layer.shadowRadius = 5
           
           NSLayoutConstraint.activate([
               profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
               profileImageView.widthAnchor.constraint(equalToConstant: 100),
               profileImageView.heightAnchor.constraint(equalToConstant: 100)
           ])
       }
       
       private func setupLabels() {
           nameLabel.text = "Sarkar"
           nameLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
           nameLabel.textColor = UIColor(hex: "#40CBD8")
           nameLabel.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(nameLabel)
           
           phoneLabel.text = "Phone: 8595428901"
           phoneLabel.font = UIFont.systemFont(ofSize: 16)
           phoneLabel.textColor = UIColor.lightGray
           phoneLabel.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(phoneLabel)
           
           NSLayoutConstraint.activate([
               nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 15),
               nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               
               phoneLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
               phoneLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
           ])
       }
       
       private func setupButtons() {
           let buttonStackView = UIStackView()
           buttonStackView.axis = .vertical
           buttonStackView.spacing = 30
           buttonStackView.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(buttonStackView)
           
           configureButton(privacyButton, title: "Privacy Settings")
           configureButton(editContactsButton, title: "Edit Contacts")
           configureButton(logoutButton, title: "Logout")
           configureButton(editProfileButton, title: "Edit Profile")

           
           buttonStackView.addArrangedSubview(privacyButton)
           buttonStackView.addArrangedSubview(editContactsButton)
           buttonStackView.addArrangedSubview(logoutButton)
           buttonStackView.addArrangedSubview(editProfileButton)
           
           NSLayoutConstraint.activate([
               buttonStackView.topAnchor.constraint(equalTo: phoneLabel.bottomAnchor, constant: 50),
               buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
               buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
           ])
       }
       
       private func configureButton(_ button: UIButton, title: String) {
           button.setTitle(title, for: .normal)
           button.backgroundColor = UIColor(hex: "#818589").withAlphaComponent(0.8)
           button.layer.cornerRadius = 12
           button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
           button.setTitleColor(.white, for: .normal)
           
           // Adding shadow
           button.layer.shadowColor = UIColor.black.cgColor
           button.layer.shadowOffset = CGSize(width: 0, height: 4)
           button.layer.shadowOpacity = 0.3
           button.layer.shadowRadius = 4
           
           button.translatesAutoresizingMaskIntoConstraints = false
           button.heightAnchor.constraint(equalToConstant: 50).isActive = true
       }
       
       // Button Actions
       @objc func privacyButtonTapped() {
           // Handle Privacy Settings
       }
       
       @objc func editContactsButtonTapped() {
           // Navigate to Edit Contacts
           let contactViewController = ContactViewController() // Replace with actual view controller
           navigationController?.pushViewController(contactViewController, animated: true)
       }
       
       @objc func logoutButtonTapped() {
           // Handle Logout
       }
       
       @objc func editProfileButtonTapped() {
           // Handle Edit Profile
       }
   }

   class ContactViewController: UIViewController {
       override func viewDidLoad() {
           super.viewDidLoad()
           view.backgroundColor = .white
           // Set up your Contact view here
       }
   }

   // Utility extension to handle hex colors
