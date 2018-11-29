//
//  AbstractChatViewController.swift
//  BeagleIM
//
//  Created by Andrzej Wójcik on 21.09.2018.
//  Copyright © 2018 HI-LOW. All rights reserved.
//

import AppKit
import TigaseSwift

class AbstractChatViewController: NSViewController, NSTableViewDataSource, ChatViewDataSourceDelegate, NSTextViewDelegate {
    
    @IBOutlet var tableView: NSTableView!;
    @IBOutlet var messageFieldScroller: NSScrollView!;
    @IBOutlet var messageField: AutoresizingTextView!;
    @IBOutlet var messageFieldScrollerHeight: NSLayoutConstraint!;
    
    var dataSource: ChatViewDataSource!;
    var chat: DBChatProtocol!;

    var account: BareJID! {
        return chat.account;
    }
    
    var jid: BareJID! {
        return chat.jid.bareJid;
    }
    
    var hasFocus: Bool {
        return DispatchQueue.main.sync { view.window?.isKeyWindow ?? false };
    }
    
    var mouseMonitor: Any?;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.dataSource.delegate = self;
        self.tableView.dataSource = self;
        self.messageField.delegate = self;
        self.messageField.isContinuousSpellCheckingEnabled = Settings.spellchecking.bool();
        self.messageField.isGrammarCheckingEnabled = Settings.spellchecking.bool();
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeKeyWindow), name: NSWindow.didBecomeKeyNotification, object: nil);
    }
    
    override func viewWillAppear() {
        super.viewWillAppear();
        self.tableView.reloadData();
        print("scrolling to", self.tableView.numberOfRows - 1)
        self.tableView.scrollRowToVisible(self.tableView.numberOfRows - 1);
        
        self.dataSource.refreshData();
        self.updateMessageFieldSize();
        
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .rightMouseDown]) { (event) -> NSEvent? in
            self.handleMouse(event: event) ? nil : event;
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear();
        NSEvent.removeMonitor(mouseMonitor);
    }
    
    override func viewDidAppear() {
        super.viewDidAppear();
        //DispatchQueue.main.async {
            if !NSEvent.modifierFlags.contains(.shift) {
                self.view.window?.makeFirstResponder(self.messageField);
            }
        //}
    }
    
    var currentSession: SelectionSession?;
    
    func handleMouse(event: NSEvent) -> Bool {
        switch event.type {
        case .leftMouseDown:
            if currentSession != nil {
                let visibleRows = self.tableView.rows(in: self.tableView.visibleRect);
                for row in visibleRows.lowerBound..<visibleRows.upperBound {
                    if let view = self.tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ChatMessageCellView {
                        let str = NSMutableAttributedString(attributedString: view.message.attributedStringValue);
                        str.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: str.length));
                        view.message.attributedStringValue = str;
                    }
                }
            }
            currentSession = nil;
        
            guard event.clickCount == 1 else {
                return false;
            }
            
            guard let messageView = messageViewFor(event: event) else {
                return false;
            }
            
            self.currentSession = SelectionSession(messageView: messageView, event: event);
            
            return currentSession != nil;
        case .leftMouseUp:
            guard let session =  currentSession else {
                return false;
            }

            return true;
        case .leftMouseDragged:
            guard let contentView = event.window?.contentView, let session = self.currentSession else {
                return false;
            }
            
            let point = self.tableView.convert(event.locationInWindow, from: nil);
            let currRow = self.tableView.row(at: point);
            let startRow = self.tableView.row(at: self.tableView.convert(session.point, from: nil));
            guard currRow >= 0 && startRow >= 0 else {
                return false;
            }
            guard let messageView = messageViewFor(event: event) else {
                return false;
            }
            guard let idx = messageView.message.characterIndexFor(event: event) else {
                return false;
            }
            
            let visibleRows = self.tableView.rows(in: self.tableView.visibleRect);
            for row in visibleRows.lowerBound..<visibleRows.upperBound {
                if let view = self.tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ChatMessageCellView {
                    let str = NSMutableAttributedString(attributedString: view.message.attributedStringValue);
                    str.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: str.length));
                    view.message.attributedStringValue = str;
                }
            }
            
            let begin = max(startRow, currRow);
            let end = min(startRow, currRow);
            for row in end...begin {
                if let view = self.tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ChatMessageCellView {
                    let str = NSMutableAttributedString(attributedString: view.message.attributedStringValue);
                    str.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: str.length));
                    if row == begin {
                        if row == end {
                            let s1 = min(session.position, idx);
                            let s2 = max(session.position, idx);
                            str.addAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, range: NSRange(location: s1, length: (s2 - s1) + 1));
                        } else {
                            let start = begin == startRow ? session.position : idx;
                            str.addAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, range: NSRange(location: start, length: (str.length - start)));
                        }
                    } else if row == end {
                        let start = end == startRow ? session.position : idx;
                        str.addAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, range: NSRange(location: 0, length: start + 1));
                    } else {
                        str.addAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, range:   NSRange(location: 0, length: str.length));
                    }
                    view.message.attributedStringValue = str;
                }
            }
            
            let selected = dataSource.getItems(fromId: session.messageId, toId: messageView.id).filter { (item) -> Bool in
                return item as? ChatMessage != nil;
                }.map { (item) -> ChatMessage in
                    return item as! ChatMessage;
            }
            let inverted = (selected.first?.id ?? 0) != session.messageId;
            
            session.selection(selected, startOffset: inverted ? idx : session.position, endOffset: inverted ? session.position : idx);
            return true;
        case .rightMouseDown:
            guard let messageView = messageViewFor(event: event) else {
                return false;
            }

            let menu = NSMenu(title: "Actions");
            var copy = menu.addItem(withTitle: "Copy text", action: #selector(copySelectedText), keyEquivalent: "");
            copy.target = self;
            copy = menu.addItem(withTitle: "Copy messages", action: #selector(copySelectedMessages), keyEquivalent: "");
            copy.target = self;
            NSMenu.popUpContextMenu(menu, with: event, for: messageView);
            return true;
        default:
            break;
        }
        return false;
    }
    
    @objc func copySelectedText(_ sender: Any) {
        NSPasteboard.general.clearContents();
        guard let session = self.currentSession else {
            return;
        }
        
        guard let selected = session.selected, let startOffset = session.startOffset, let endOffset = session.endOffset, !selected.isEmpty else {
            return;
        }
        
        var text: [String] = [];
        if selected.count == 1 {
            let item = selected[0];
            let from = item.message.index(item.message.startIndex, offsetBy: min(startOffset, endOffset))
            let to = item.message.index(item.message.startIndex, offsetBy: max(startOffset, endOffset));
            text.append(String(item.message[from...to]));
        } else {
            for (pos, item) in selected.enumerated() {
                if pos == 0 {
                    let from = item.message.index(item.message.startIndex, offsetBy: startOffset);
                    text.append(String(item.message[from..<item.message.endIndex]));
                } else if pos == (selected.count - 1) {
                    let to = item.message.index(item.message.startIndex, offsetBy: endOffset);
                    text.append(String(item.message[item.message.startIndex...to]));
                } else {
                    text.append(item.message);
                }
            }
        }

        NSPasteboard.general.setString(text.joined(separator: "\n"), forType: .string);
    }
    
    @objc func copySelectedMessages(_ sender: Any) {
        NSPasteboard.general.clearContents();
        guard let session = self.currentSession else {
            return;
        }
        
        guard let selected = session.selected, !selected.isEmpty else {
            return;
        }
        
        let dateFormatter = DateFormatter();
        dateFormatter.locale = Locale(identifier: "en_US_POSIX");
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss";
        
        let rosterStore = XmppService.instance.getClient(for: account)?.rosterStore;
        
        let text = selected.map { (item) -> String in
            let name: String = rosterStore?.get(for: chat.jid.withoutResource)?.name ?? chat.jid.localPart ?? chat.jid.domain;
            return "[\(dateFormatter.string(from: item.timestamp))] <\(item.authorNickname ?? name)> \(item.message)";
        };
        
        NSPasteboard.general.setString(text.joined(separator: "\n"), forType: .string);
    }
    
    func messageViewFor(event: NSEvent) -> ChatMessageCellView? {
        guard let contentView = event.window?.contentView else {
            return nil;
        }
        let point = contentView.convert(event.locationInWindow, to: nil);
        guard let textView = contentView.hitTest(point) as? NSTextField else {
            return nil;
        }
        guard let view = textView.superview as? ChatMessageCellView else {
            return nil;
        }
        return view;
    }
    
    @objc func didBecomeKeyWindow(_ notification: Notification) {
        if chat.unread > 0 {
            DBChatHistoryStore.instance.markAsRead(for: account, with: jid);
        }
    }
    
    func textDidChange(_ notification: Notification) {
        self.updateMessageFieldSize();
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard "\n" == replacementString else {
            return true;
        }
        DispatchQueue.main.async {
            let msg = textView.string;
            guard !msg.isEmpty else {
                return;
            }
            guard self.sendMessage(body: msg) else {
                return;
            }
            self.messageField.reset();
            self.updateMessageFieldSize();
        }
        return false;
    }
    
    func itemAdded(at rows: IndexSet) {
        tableView.insertRows(at: rows, withAnimation: NSTableView.AnimationOptions.slideLeft)
        if (rows.contains(0)) {
            tableView.scrollRowToVisible(0);
        }
    }
    
    func itemUpdated(indexPath: IndexPath) {
        tableView.reloadData(forRowIndexes: [indexPath.item], columnIndexes: [0]);
    }
    
    func itemsReloaded() {
        tableView.reloadData();
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource.count;
    }

    func sendMessage(body: String? = nil, url: String? = nil) -> Bool {
        return false;
    }
    
    func updateMessageFieldSize() {
        let height = min(max(messageField.intrinsicContentSize.height, 14), 100) + self.messageFieldScroller.contentInsets.top + self.messageFieldScroller.contentInsets.bottom;
        self.messageFieldScrollerHeight.constant = height;
    }
    
    class SelectionSession {
        
        let messageId: Int;
        let position: Int;
        let point: NSPoint;
        
        fileprivate(set) var selected: [ChatMessage]?;
        fileprivate(set) var startOffset: Int?;
        fileprivate(set) var endOffset: Int?;
        
        init?(messageView: ChatMessageCellView, event: NSEvent) {
            self.messageId = messageView.id;
            guard let position = messageView.message!.characterIndexFor(event: event) else {
                return nil;
            }
            self.position = position;
            self.point = event.locationInWindow;
        }
        
        func selection(_ selected: [ChatMessage], startOffset: Int, endOffset: Int) {
            self.selected = selected;
            self.startOffset = startOffset;
            self.endOffset = endOffset;
        }
    }
}

extension NSTextField {
 
    func characterIndexFor(event: NSEvent) -> Int? {
        guard let contentView = event.window?.contentView else {
            return nil;
        }
        
        let point = contentView.convert(event.locationInWindow, from: nil);
        let textPoint = convert(point, from: contentView);
        
        let textContainer:NSTextContainer = NSTextContainer.init()
        let layoutManager:NSLayoutManager = NSLayoutManager.init()
        let textStorage:NSTextStorage = NSTextStorage.init()
        layoutManager.addTextContainer(textContainer);
        textStorage.addLayoutManager(layoutManager);
        
        layoutManager.typesetterBehavior = .latestBehavior;
        textContainer.containerSize = (self.cell as! NSTextFieldCell).controlView!.bounds.size;
        
        textStorage.beginEditing();
        textStorage.setAttributedString(self.attributedStringValue);
        textStorage.endEditing();
        
        return layoutManager.characterIndex(for: textPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil);
    }
}
