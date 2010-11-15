console.log("Loading Location...")

Spontaneous.Location = (function($, S) {
	var ajax = S.Ajax;

	var State = new JS.Class({
		initialize: function(hash) {
			this.page_id = false;
			if (hash) {
				this.hash = hash.substr(1);
				this.parse_hash();
			}
		},
		// make this more sophisticated to deal with more complex state
		parse_hash: function() {
			var parts = this.hash.split('/')
			parts.shift();
			if (parts.length > 0) {
				this.page_id = parts[0];
			}
		},
		restore: function() {
			if (this.page_id) {
				Spontaneous.Location.load_id(this.page_id);
			} else {
				Spontaneous.Location.load_path('/');
			}
		},
		to_hash: function() {
			return '#/'+(this.page_id || '');
		}
	});

	State.extend({
		restore: function() {
			var state = new State(window.location.hash)
			state.restore();
		},
		page: function(location) {
			var s = new State
			s.page_id = location.id;
			window.location.hash = s.to_hash();
		}
	});

	var Location = new JS.Singleton({
		include: Spontaneous.Properties,
		init: function(callback) {
			var complete = function() {
				callback();
				this.location_loaded();
			}.bind(this);
			callback();
			State.restore();
			$(window).bind('hashchange', State.restore);
		},
		page_loaded: function(page) {
			console.log('Location.page_loaded', page, page.uid());
			page.add_listener('slot', this, 'slot_changed');
		},
		slot_changed: function(slot) {
			console.log('Location.slot_changed', slot, slot.uid(), slot.container.id());
		},
		load_map: function() {
		},
		location_loaded: function(location) {
			this.set('location', location);
			State.page(location);
		},
		load_id: function(id) {
			var l = this.location();
			if (!l || id != l.id) {
				this.find_id(id);
			}
		},
		load_path: function(path) {
			this.find_path(path);
		},
		url: function() {
			var l = this.location();
			return (l ? l.url : "/about");
		},
		location: function() {
			return this.get('location');
		},
		update: function(location) {
			this.set('location', location);
			this.path_from_url(location.url)
		},
		current_path: function() {
			return this.path_from_url(this.url());
		},
		find_path: function(path) {
			if (this.location() && path === this.location().path) {
				return this.location();
			}
			ajax.get('/location'+path, this, this.location_loaded);
		},
		find_id: function(id) {
			if (this.location() && id === this.location().id) {
				return this.location();
			}
			ajax.get('/map/'+id, this, this.location_loaded);
		},
		path_from_url: function(url) {
			var map = this.get('map'),
			children = map.children,
			path = [], i, ii,
			parts = url.split('/').slice(1), position = 0;
			// add root to path
			path.push({selected:0, pages:[ map ], root:true});;
			while (position < parts.length) {
				for (i = 0, ii = children.length; i < ii; i++) {
					var child = children[i], slug = child.url.split('/').slice(-1)[0];
					if (slug === parts[position]) {
						path.push({selected:i, pages: children});
						children = child.children;
						break;
					}
				}
				position += 1;
			}
			return path;
		}
	});
	return Location;
})(jQuery, Spontaneous);


