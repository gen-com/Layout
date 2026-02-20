//
//  MemoDummyDataGenerator.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import Foundation

struct MemoDummyDataGenerator {
  struct Sample {
    let content: String
    let date: Date
  }

  func generateMemoSample() -> Sample {
    Sample(content: generateMemoContent(), date: generateMemoDate())
  }

  private func generateMemoContent() -> String {
    let title = randomMemoTitles.randomElement() ?? "Untitled"
    let short = randomMemoBodiesShort.randomElement() ?? ""
    let medium = randomMemoBodiesMedium.randomElement() ?? ""
    let long = randomMemoBodiesLong.randomElement() ?? ""

    let body: String
    switch Int.random(in: 0...4) {
    case 0:
      body = short
    case 1, 2:
      body = medium
    default:
      body = [medium, long].joined(separator: "\n\n")
    }

    return [title, body]
      .filter { $0.isEmpty == false }
      .joined(separator: "\n")
  }

  private func generateMemoDate() -> Date {
    let randomSecondsInWeek = TimeInterval(Int.random(in: 0...(7 * 24 * 60 * 60)))
    return Date().addingTimeInterval(-randomSecondsInWeek)
  }
}

private extension MemoDummyDataGenerator {
  var randomMemoTitles: [String] {
    [
      "Meeting Notes",
      "Quick Idea",
      "Today Reminder",
      "Shopping List",
      "Workout Plan",
      "Travel Plan"
    ]
  }

  var randomMemoBodiesShort: [String] {
    [
      "Call Alex at 3 PM.",
      "Buy milk and eggs.",
      "Draft intro paragraph.",
      "Stretch for 10 minutes."
    ]
  }

  var randomMemoBodiesMedium: [String] {
    [
      "Check progress and share updates before noon.\nFocus on blockers first and propose one concrete next step.",
      "Organize tasks by priority and deadline.\nStart with the smallest task to build momentum.",
      "Book tickets and confirm accommodation details.\nKeep all reservation numbers in one note.",
      "Review this week goals and adjust tomorrow plan.\nLeave a short buffer for unexpected work."
    ]
  }

  var randomMemoBodiesLong: [String] {
    [
      "Project A: finalize scope and confirm ownership for each deliverable.\nProject B: capture open questions and schedule a review session.\nPersonal: clean workspace, back up laptop, and prepare materials for tomorrow.\n\nIf time allows, write a short retrospective about what worked well this week and what should change next week.",
      "Morning routine:\n1) 20-minute run\n2) shower and breakfast\n3) planning session for top three outcomes.\n\nWork block:\n- complete API integration\n- verify error handling paths\n- update documentation with examples.\n\nEvening:\n- quick grocery run\n- prepare clothes for tomorrow\n- read for 30 minutes before sleep."
    ]
  }
}
