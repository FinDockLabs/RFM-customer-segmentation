[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](/LICENSE)

# RFM Customer Segmentation

> The RFM Customer Segmentation app is dependent on the FinDock package

The RFM model is a customer segmentation technique that is used to analyze customer value. RFM stands for Recency, Frequency, and Monetary Value. With the usage of the transactional data of your customers RFM-scores can be calculated per unique customer. Based on the RFM-scores a customer falls in a certain segment.

This RFM Customer Segmentation app applies the RFM model to your customers in Salesforce using FinDock data. Four fields are added to the standard Contact object in Salesforce:
- **Recency Score**: is based on the number of days between the contact most recent payment and today.
- **Frequency Score**: is based on the number of payments attached to the contact.
- **Monetary value Score**: is based on the sum of payments attached to the contact.
- **RFM Segment**: is based on the Recency score & Frequency score of the contact.

The RFM calculation is done using the FinDock Payment object as a basis. Per customer is takes all payments into account where the payment matches the following criteria:
- The related Installment status is equal to `Collected`
- The related Installment recordtype is equal to `Receivable`
- The collection date is after the `Date Range Start` date given in the settings

The RFM scores and the customer segment is stored on field level on every contact record in Salesforce. It can also be visualized both in a per customer view and in an org-wide view over all contacts in the Salesforce org. See the screenshots below.

![RFM Contact view](/docs/assets/rfm-contact-view.png "RFM Contact view")
![RFM Grid](/docs/assets/rfm-grid-view.png "RFM Org-wide view")

# Installation and configuration

1. Install the latest package version in your Salesforce environment: [releases](https://github.com/FinDockLabs/RFM-customer-segmentation/releases/).
2. Assign the following permission set to each user who will need to use RFM Customer Segmentation package: `Engagement Grid`
3. Add the lightning component `ContactRFMScoreDisplay` to the contact page. 
3. From the App Launcher go to the `RFM Customer Segmentation` app. 
4. Start the initial calculation of the RFM scores and segments of your contacts by clicking on the `Refresh Data` button. 
5. (optional) Click on the `RFM Settings` tab. Schedule the heartbeat on the time of your choosing.

Please note that the Customer Segment and RFM-scores will be calculated using the default settings. Many of these settings can be configured via the `RFM Settings` tab.

# Contributing

When contributing to this repository, please first discuss the change you wish to make via an issue or any other method with FinDock before making a change.

# Support

FinDock Labs is a non-supported group in FinDock that releases applications. Despite the name, assistance for any of these applications is not provided by FinDock Support because they are not officially supported features. For a list of these apps, visit the FinDock Labs account on Github. 

# License

This project is licensed under the MIT License - see the [LICENSE](/LICENSE) file for details
