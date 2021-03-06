library EventManager;

class GameEvent {
    Map args;
    List<String> recipients;

    GameEvent() {
        args = new Map();
        recipients = new List();
    }
}

class Listener {
    List<GameEvent> events;
    Listener() {
        events = new List();
    }
}

class EventManager {
    Map<String, Listener> listeners;
    List events;

    EventManager() {
        listeners = new Map();
        events = new List();
    }

    void addEvent(GameEvent e) {
        events.add(e);
    }

    void addListener(String name, Listener listener) {
        listeners[name] = listener;
    }

    void delegateEvents() {
        for (var event in events) {
            for (var recipient in event.recipients) {
                var listener = listeners[recipient];
                if (listener != null) {
                    listener.events.add(event);
                }
            }
        }
        events.clear();
    }
}