//
//  CrashReportingViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/24/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit
import Eureka
import FirebaseCrashlytics
import FirebaseAnalytics

class CrashReportingViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Crash Reporting & Analytics"

        // Do any additional setup after loading the view.
        let footerMessage = "Enables crash reporting and analytics for Deluge Remote (anonymously), which greatly helps to improve the app by aiding the developer in understanding crashes and issues, as well as provides information (for example on which features are being used) to help make better development decisions."
        form +++ Section(footer: footerMessage)
            <<< SwitchRow() {
                $0.title = "Crash Reporting & Analytics"
                $0.value = Crashlytics.crashlytics().isCrashlyticsCollectionEnabled()
            }.onChange { row in
                Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(row.value ?? true)
                Analytics.setAnalyticsCollectionEnabled(row.value ?? true)
            }
    }

}
