//
//  ScheduleTableViewController.swift
//  BrickHack-Mobile
//
//  Created by Peter Kos on 1/20/20.
//  Copyright © 2020 codeRIT. All rights reserved.
//

import UIKit
import TimelineTableViewCell
import SwiftMessages
import UserNotifications

class ScheduleTableViewController: UITableViewController, UNUserNotificationCenterDelegate {

    // MARK: Ivars
    var scheduleTimer = Timer()

    // Colors for dataset
    // @TODO: Double check w/ design on these colors
    let backColor = UIColor(named: "primaryColor")!
    let frontColor = UIColor(named: "timelineBackColor")!

    // Custom wrapper struct around an Event, to store additional UI parameters. Namely:
    // timelinePoint: whether or not the event has a dot to the left
    // allColor: a defined color for the timeline, for this event
    class TimelineEvent: CustomStringConvertible {
        var timelinePoint: TimelinePoint?
        var isFavorite: Bool
        var allColor: UIColor
        var event: Event

        init(timelinePoint: TimelinePoint?, isFavorite: Bool, allColor: UIColor, event: Event) {
            self.timelinePoint = timelinePoint
            self.isFavorite = isFavorite
            self.allColor = allColor
            self.event = event
        }

        convenience init(allColor: UIColor, event: Event) {
            self.init(timelinePoint: nil, isFavorite: false, allColor: allColor, event: event)
        }

        convenience init() {
            self.init(timelinePoint: nil, isFavorite: false, allColor: UIColor.clear, event: Event())
        }

        var description: String {
            return "\(event)"
        }
    }
    var timelineEvents = [TimelineEvent]()


    override func viewDidLoad() {
        super.viewDidLoad()

        // Register the nib for TimelineTBVCell
        let nibURL = Bundle(for: TimelineTableViewCell.self).url(forResource: "TimelineTableViewCell", withExtension: "bundle")
        let timelineTableViewCellNib = UINib(nibName: "TimelineTableViewCell", bundle: Bundle(url: nibURL!)!)
        tableView.register(timelineTableViewCellNib, forCellReuseIdentifier: "TimelineTableViewCell")

        // Remove separator lines
        tableView.separatorStyle = .none

        // Set timer for timeline refresh function,
        // which runs every 30 minutes (while the screen is visible) and updates the timeline view if necessary.
        scheduleTimer = Timer.scheduledTimer(timeInterval: (60.0 * 30), target: self, selector: #selector(refreshTimeline), userInfo: nil, repeats: true)
        scheduleTimer.fire()
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Stop timer when view is not visible
        scheduleTimer.invalidate()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // This property is stored in the ScheduleParser,
        // as this is pretty much the only time it's needed here.
        return ScheduleParser.sectionCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of events with a matching section number
        return timelineEvents.filter({ $0.event.section == section }).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineTableViewCell", for: indexPath) as! TimelineTableViewCell
        let currentTimelineEvent = timelineEvents[convertIndex(fromIndexPath: indexPath)]

        /*
        Overview of how cells are drawn

                       ----------------
         backColor     |
         tPoint.color  o Title (bold)
                       |
         frontColor    | Description
                       |
                       ----------------
         */

        // Colors, and point
        // If point is nil, stick zero width point there
        cell.backgroundColor = UIColor.clear
        cell.timeline.backColor = currentTimelineEvent.allColor
        cell.timelinePoint = currentTimelineEvent.timelinePoint ??
            TimelinePoint(diameter: 0, color: currentTimelineEvent.allColor, filled: true)
        cell.timeline.frontColor = currentTimelineEvent.allColor

        // If point is filled, set FRONTCOLOR to match rest of list, and show bubble.
        // (point is current bit)
        if (currentTimelineEvent.timelinePoint?.isFilled ?? false) {
            // These colors are a bit counterintuitive but it works ¯\_(ツ)_/¯
            cell.timeline.backColor = frontColor
            // Sets white text no matter what, due to contrastive background of bubble (set later in method)
            cell.titleLabel.textColor = UIColor.white
            cell.bubbleEnabled = true
        } else {
            // Only current item gets button.
            cell.bubbleEnabled = false

            // Reset label color as this previously-current item is no longer current
            if #available(iOS 13.0, *) {
                cell.titleLabel.textColor = UIColor.label
            } else {
                cell.titleLabel.textColor = UIColor.black
            }
        }

        // Text content
        // Note "description" is our own property!
        cell.titleLabel.text = currentTimelineEvent.event.title
        cell.descriptionLabel.text = currentTimelineEvent.event.description

        // Configure favorite accessory
        let favButton = FavoriteButton(type: .custom)
        // Set images
        favButton.addTarget(self, action: #selector(favoriteTapped(sender:)), for: .touchUpInside)
        cell.accessoryView = favButton
        // Make "favorite" star a bit bigger
        cell.accessoryView?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        // Set custom properties
        favButton.section = indexPath.section
        favButton.row = indexPath.row
        favButton.sizeToFit()

        // Now, toggle the stars that are favorited
        favButton.isSelected = currentTimelineEvent.isFavorite

        // Confgure bubble
        cell.bubbleColor = UIColor(named: "primaryColor")!
        cell.bubbleBorderColor = UIColor.clear

        // Disable selection per cell
        cell.selectionStyle = .none

        // Layout adjustment
        // (Accessory adjustment is done in @peterkos/TimelineTableViewCell)
        cell.timeline.leftMargin = 30.0

        return cell
    }


    // MARK: Some helper functions

    // Helper function to get a global index for an event from its local table index
    // Section > Row:
    // 0
    //   0
    //   1
    // 1
    //   0     This has global index 2, local index 0.
    private func convertIndex(fromIndexPath indexPath: IndexPath) -> Int {

        var eventSum = 0

        for secIndex in 0..<indexPath.section {
            let eventsInSection = timelineEvents.filter({ $0.event.section == secIndex })
            eventSum += eventsInSection.count
        }

        // This gets the index to the SECTION.
        // Now, we need to increment it relative to the section
        // to find out corresponding row's absolute index.
        // (debug time for this: 1.5 hours)
        return eventSum + indexPath.row
    }

    // Because of the Wonderful Way UIKit works (https://stackoverflow.com/a/12810613/1431900),
    // we have to define our own UIButton + handler for this accessoryView.
    // To get two points of data (section + row) instead of just one `tag`,
    // we use a subclassed UIButton, FavoriteButton, so we know what exact
    // event was pressed. (row is section-dependent)
    @objc func favoriteTapped(sender: UIButton) {

        // Reject if improper call
        guard let favButton = sender as? FavoriteButton else {
            MessageHandler.showInvalidFavoriteButtonError()
            return
        }

        // Reject if indices are invalid
        guard favButton.section != nil && favButton.row != nil else {
            MessageHandler.showInvalidFavoriteButtonError()
            return
        }

        // Update view
        // (FavoriteButton subclass handles updating this condition)
        favButton.isSelected = !favButton.isSelected

        // Now, prep the model:

        // Get the event at this position
        let indexPath = IndexPath(row: favButton.row!, section: favButton.section!)
        let selectedEvent = timelineEvents[convertIndex(fromIndexPath: indexPath)]

        // Update model
        selectedEvent.isFavorite = !selectedEvent.isFavorite

        // Manage the list of events
        if selectedEvent.isFavorite {
            scheduleFavoriteNotification(forEvent: selectedEvent)
            print("Scheduled notification for \(selectedEvent.event.title)")
        } else {
            unscheduleFavoriteNotification(forEvent: selectedEvent)
            print("Unscheduled notification for \(selectedEvent.event.title)")
        }

        // @TODO: Handle updating favorite with server
    }

    // MARK: Notifications
    private func scheduleFavoriteNotification(forEvent timelineEvent: TimelineEvent) {

        askForNotificationPermissionIfNeeded()

        // If this looks complicated, see this StackOverflow answer:
        // https://stackoverflow.com/a/60134234/1431900
        let now = Date(timeIntervalSinceNow: 0)

        // If event has already occured, silently fail.
        if (timelineEvent.event.time < now) {
            return
        }

        // Otherwise, let's calculate the time until the next event
        let interval = timelineEvent.event.time.timeIntervalSince(Date(timeIntervalSinceNow: 0))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = timelineEvent.event.title + " is starting!"
        content.body = timelineEvent.event.description
        content.sound = .default
        let request = UNNotificationRequest(identifier: timelineEvent.event.uuid, content: content, trigger: trigger)

        // Add request to local notification center
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                DispatchQueue.main.async {
                    MessageHandler.showNotificationRegisterError(withEventTitle: timelineEvent.event.title)
                }
                return
            }
        }
    }

    private func unscheduleFavoriteNotification(forEvent timelineEvent: TimelineEvent) {
        let identifier = timelineEvent.event.uuid
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private func askForNotificationPermissionIfNeeded() {

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in

            print("NOTIF ERROR: \(error)")
            if !granted {
                DispatchQueue.main.async {
                    MessageHandler.showNotificationDisabledInfo()
                }
            } else {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: Section headers and view configuration

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        // Get our dummy cell from IB
        let cell = tableView.dequeueReusableCell(withIdentifier: "header")!

        // Make date formatter for just time
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none

        // Return cell as-is if invlaid data
        guard let sectionDate = timelineEvents.filter({ $0.event.section == section }).first?.event.timeString else {
            cell.textLabel!.text = "Unknown Time"
            return cell
        }

        // Otherwise set proper date
        cell.textLabel!.text = sectionDate

        return cell

    }

    // Defined height for the time header slot (e.g., "9am")
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }

    // Remove margin between sections
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    // Set on a Timer to run every so often
    // Updates the timer dispay to highlight the current event.
    // Note: The topmost event is ALWAYS highlighted, even if it has not occured yet.
    // (This is done in the dequeueCell tableview delegtae method)
    @objc func refreshTimeline() {

        // First, get an updated verison of the schedule
        // (Handles UI, threaded)
        updateSchedule() {

            // Don't parse if no sections available
            // (Sanity guard, shouldn't happen)
            guard ScheduleParser.sectionCount >= 1 else {
                print("nope")
                return
            }

            // Start at -1 as we look at the next index to see if the current is over yet
            // (Updating each section as "current" as we go)
            print("sectionCount: \(ScheduleParser.sectionCount)")
            for sectionIndex in 0..<ScheduleParser.sectionCount {

                // Grab the next section's date
                let events = self.timelineEvents.filter({ $0.event.section == sectionIndex })
                let sectionDate = events.first!.event.time

                // If greater, STOP. We are at the current section.
                if (sectionDate > Date(timeIntervalSinceNow: 0)) {
                    break
                }

                // Otherwise, go on to configure this current section as "passed"
                self.timelineEvents.filter({ $0.event.section == sectionIndex }).forEach { timelineEvent in
                    timelineEvent.allColor = self.backColor
                }

                let mostCurrentEvent = self.timelineEvents.filter({ $0.event.section == sectionIndex }).last
                mostCurrentEvent?.timelinePoint = TimelinePoint(color: self.backColor, filled: true)

                // Remove it from the previous section
                let lastCurrentEvent = self.timelineEvents.filter({ $0.event.section == sectionIndex - 1}).last
                lastCurrentEvent?.timelinePoint = nil
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

        }

    }

    // Updates the listing of events from the Google Sheet
    func updateSchedule(completion: @escaping () -> ()) {

        // Create custom toast to use for alerting the user
        let toastView = MessageView.viewFromNib(layout: .messageView)
        // Hide controls we don't want
        toastView.button?.isHidden = true
        toastView.bodyLabel?.isHidden = true
        // Create a bit more of a custom theme (dark mdoe safe!)
        toastView.configureTheme(.info)
        toastView.backgroundColor = UIColor.systemBlue
        toastView.titleLabel!.textColor = UIColor.white
        toastView.iconImageView?.tintColor = UIColor.white

        var toastConfig = SwiftMessages.Config()
        toastConfig.presentationStyle = .bottom
        toastConfig.duration = .indefinite(delay: 0.0, minimum: 2.0)

        DispatchQueue.main.async {
            // Show toast to user
            toastView.configureContent(title: "Getting the latest events...", body: "")
            SwiftMessages.show(config: toastConfig, view: toastView)
        }

        // Do it
        ScheduleParser.retrieveEvents {

            // On completion, update our copy of events
            // First, get a list of current events
            let favoriteEvents = self.timelineEvents.filter({ $0.isFavorite })
            print("Favorites: \(favoriteEvents)")

            // (Rewrite instead of merge because merge logic is hard)
            self.timelineEvents.removeAll()

            print("\nCleared timeline events.\n")
            for event in ScheduleParser.events {
                let newEvent = TimelineEvent(allColor: self.frontColor, event: event)

                // Add favorite tag back if previously favorited
                if favoriteEvents.filter({ $0.event.uuid == newEvent.event.uuid }).first != nil {
                    print("found favorite \(newEvent)")
                    newEvent.isFavorite = true
                }

                self.timelineEvents.append(newEvent)
            }

            completion()

            // Finally, update the table now that our model is full
            DispatchQueue.main.async {

                self.tableView.reloadData()

                // Show toast to user
                toastView.configureContent(title: "Schedule updated!", body: "")
                SwiftMessages.hide()
            }
        }
    }

}
