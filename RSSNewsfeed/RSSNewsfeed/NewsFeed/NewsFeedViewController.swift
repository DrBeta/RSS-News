//
//  NewsFeedViewController.swift
//  RSSNewsfeed
//
//  Created by Viktor S on 5/2/19.
//  Copyright © 2019 Viktor S. All rights reserved.
//

import UIKit
import SWRevealViewController
import Kingfisher
import RealmSwift

class NewsFeedViewController: UIViewController {
    
    // MARK: - IBOutlets & IBActions
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    let viewModel = NewsFeedViewModel()
    var xmlParser : NewsFeedXMLParser!
    let networkReachability = NetworkReachability()
    var isOffline = true

    
    // MARK: - LoadView
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.populateDefaultSources()

        // Navigation
        menuButton.target = self.revealViewController()
        menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        self.navigationItem.title = viewModel.currentChannelName
        
        xmlSetup()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        

}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        networkCheck()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on the next view controllers
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
    }
    
    // MARK: - Methods
    func networkCheck() {
        if networkReachability.isNetworkAvailable() {
            isOffline = false
            xmlParse()
        } else {
            isOffline = true
            self.showAlert(errorTitle: "Network is unavailable", errorMessage: "Please check you connection and select newssource once again.")
            
        }
    }
    
    fileprivate func xmlSetup() {
        xmlParser = NewsFeedXMLParser()
        xmlParser.delegate = self

        
        if viewModel.currentNewsSourceModel == nil {
            guard let selectedNewsSourceModel = try! Realm().object(ofType: NewsSource.self, forPrimaryKey: "Wired") else { return }
            viewModel.currentNewsSourceModel = selectedNewsSourceModel
        }
        xmlParser.newsModel = viewModel.currentNewsSourceModel
    }
    
    fileprivate func xmlParse() {
        
        guard let url = URL(string: viewModel.currentNewsChannelSource) else { return }

        xmlSetup()
        xmlParser.startParsingWithContentsOfURL(rssURL: url)
    }
    
    fileprivate func open(url: String, currentRow: Int) {
        
        if let checkedURL = URL(string: url) {
            
            UIApplication.shared.open(checkedURL, options: [:]) { _ in
                
                // get current item and deselect it
                let index = IndexPath(row: currentRow, section: 0)
                self.tableView.deselectRow(at: index, animated: true)
                                
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showWebView" {
            
                if let webViewController = segue.destination as? WebViewController {
                    
                    guard let selectedChannelIndex = tableView.indexPathForSelectedRow else { return }
                    
                    let currentDictionary = xmlParser.arrParsedData[selectedChannelIndex.row] as [String: String]

                    if let link = currentDictionary["link"] {
                        webViewController.url = URL(string: link)
                    }
                }
            }
        }
    }

// MARK: - UITableViewDataSource Methods
extension NewsFeedViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard xmlParser != nil else { return 0 }
        return xmlParser.arrParsedData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let newsFeedCell = tableView.dequeueReusableCell(withIdentifier: "newsFeedCell") as? NewsFeedTableViewCell else { return UITableViewCell() }
        
        let currentDictionary = xmlParser.arrParsedData[indexPath.row] as [String: String]
        
        if let url = currentDictionary["media:thumbnail"] {
            newsFeedCell.newsImage.kf.setImage(with: URL(string: url))
        }

        newsFeedCell.newsTitle.text = currentDictionary["title"]
        
        return newsFeedCell
    }
}

// MARK: - UITableViewDelegate Methods
extension NewsFeedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 201
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showWebView", sender: nil)
    }
}

extension NewsFeedViewController: NewsFeedXMLParserDelegate {
    func parsingWasFinished() {
        self.tableView.reloadData()
    }
}
