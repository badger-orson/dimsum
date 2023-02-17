
-- Library table
CREATE TABLE IF NOT EXISTS library (
    id INT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL UNIQUE,
    media_type TEXT NOT NULL
);

ALTER TABLE library ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS indexed_paths (
    id INTEGER PRIMARY KEY NOT NULL,
    -- must be absolute path
    location TEXT NOT NULL UNIQUE,
    library_id INTEGER NOT NULL,

    FOREIGN KEY (library_id) REFERENCES library(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS assets (
    id INTEGER PRIMARY KEY,
    remote_url TEXT UNIQUE,
    local_path TEXT NOT NULL UNIQUE,
    file_ext TEXT NOT NULL
);

-- Media table
-- This table contains the template for
-- the movie and tv shows tables minus containing
-- the paths because movies are streamable while
-- tv shows generally arent
-- The Episodes table will also inherit from here
CREATE TABLE IF NOT EXISTS _tblmedia (
    id INTEGER NOT NULL,
    library_id INTEGER NOT NULL,

    name TEXT NOT NULL,
    description TEXT,
    rating REAL,
    year INTEGER,
    added TEXT,
    poster INTEGER,
    backdrop INTEGER,
    media_type TEXT NOT NULL,
    PRIMARY KEY (id),

    FOREIGN KEY (library_id) REFERENCES library(id) ON DELETE CASCADE,
    FOREIGN KEY (poster) REFERENCES assets(id),
    FOREIGN KEY (backdrop) REFERENCES assets(id)
);

CREATE TABLE IF NOT EXISTS _tblseason (
    id INTEGER,
    season_number INTEGER NOT NULL,
    tvshowid INTEGER NOT NULL,
    added TEXT,
    poster INTEGER,
    PRIMARY KEY (id),
    
    FOREIGN KEY(poster) REFERENCES assets(id),
    FOREIGN KEY(tvshowid) REFERENCES _tblmedia (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS episode (
    id INTEGER,
    seasonid INTEGER NOT NULL,
    episode_ INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(id) REFERENCES _tblmedia (id) ON DELETE CASCADE,
    FOREIGN KEY(seasonid) REFERENCES _tblseason (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mediafile (
    -- FIXME: Have to specify NOT NULL explictly otherwise sqlx thinks this field is nullable
    id INTEGER NOT NULL,
    media_id INTEGER, -- Optional, populated on metadata search
    library_id INTEGER NOT NULL,
    target_file TEXT NOT NULL UNIQUE,

    raw_name TEXT NOT NULL,
    raw_year INTEGER,

    quality TEXT,
    codec TEXT,
    container TEXT,
    audio TEXT,
    original_resolution TEXT,
    duration INTEGER,
    
    episode INTEGER,
    season INTEGER,

    corrupt BOOLEAN,
    PRIMARY KEY (id),

    FOREIGN KEY(media_id) REFERENCES _tblmedia (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(library_id) REFERENCES library(id) ON DELETE CASCADE
);

ALTER TABLE mediafile ADD COLUMN channels INTEGER;
ALTER TABLE mediafile ADD COLUMN profile TEXT;
ALTER TABLE mediafile ADD COLUMN audio_language TEXT;

CREATE TABLE IF NOT EXISTS invites (
    id TEXT PRIMARY KEY NOT NULL UNIQUE,
    date_added INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    username TEXT PRIMARY KEY,
    password TEXT NOT NULL,
    prefs BYTEA NOT NULL DEFAULT '{}',
    claimed_invite TEXT NOT NULL UNIQUE,
    roles TEXT[] NOT NULL DEFAULT '{User}',
    picture INTEGER UNIQUE,

    FOREIGN KEY(claimed_invite) REFERENCES invites(id),
    FOREIGN KEY(picture) REFERENCES assets(id)
);

CREATE TABLE IF NOT EXISTS progress (
    id INTEGER NOT NULL,
    user_id TEXT NOT NULL,
    delta INTEGER NOT NULL,
    media_id INTEGER NOT NULL,
    populated INTEGER NOT NULL,

    PRIMARY KEY (id),
    FOREIGN KEY(media_id) REFERENCES _tblmedia (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(username) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS genre (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS genre_media (
    id INTEGER PRIMARY KEY,
    genre_id INTEGER NOT NULL,
    media_id INTEGER NOT NULL,
    FOREIGN KEY (media_id) REFERENCES _tblmedia(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genre(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS media_posters (
    id INTEGER PRIMARY KEY,
    media_id INTEGER NOT NULL,
    asset_id INTEGER NOT NULL,

    FOREIGN KEY (media_id) REFERENCES _tblmedia(id) ON DELETE CASCADE,
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS media_backdrops (
    id INTEGER PRIMARY KEY,
    media_id INTEGER NOT NULL,
    asset_id INTEGER NOT NULL,

    FOREIGN KEY (media_id) REFERENCES _tblmedia(id) ON DELETE CASCADE,
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
);

ALTER TABLE users RENAME TO old_users;
ALTER TABLE progress RENAME TO old_progress;

CREATE TABLE IF NOT EXISTS users (
    id SERIAL NOT NULL PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    prefs BYTEA NOT NULL DEFAULT '{}',
    claimed_invite TEXT NOT NULL UNIQUE,
    roles TEXT[] NOT NULL DEFAULT '{User}',
    picture INTEGER UNIQUE,

    FOREIGN KEY(claimed_invite) REFERENCES invites(id),
    FOREIGN KEY(picture) REFERENCES assets(id)
);

INSERT INTO users (username, password, prefs, claimed_invite, roles, picture) SELECT * FROM old_users;

CREATE TABLE IF NOT EXISTS progress (
    id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    delta INTEGER NOT NULL,
    media_id INTEGER NOT NULL,
    populated INTEGER NOT NULL,

    PRIMARY KEY (id),
    FOREIGN KEY(media_id) REFERENCES _tblmedia (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- INSERT INTO progress (id, user_id, delta, media_id, populated)
-- SELECT op.id, u.id, op.delta, op.media_id, op.populated
-- FROM old_progress op
-- JOIN users u
-- ON op.user_id=u.username;

DROP TABLE old_users CASCADE;
DROP TABLE old_progress;

-- -- DB table IS CREATED, used so we do not recreate the DB over and over, dont just trust the "IF NOT EXISTS"
CREATE TABLE IF NOT EXISTS dbcreated (
	id INT PRIMARY KEY NOT NULL DEFAULT 0	
);

-- --DB IS CREATED SO WE CAN INSERT, INTO THE TABLE A 1 FOR CREATION BOOL

INSERT INTO dbcreated(id)
VALUES (1);

--CREATE VIEWS -- --

CREATE VIEW media AS
SELECT _tblmedia.*, pp.local_path as poster_path, bp.local_path as backdrop_path
FROM _tblmedia
LEFT OUTER JOIN assets pp ON _tblmedia.poster = pp.id
LEFT OUTER JOIN assets bp ON _tblmedia.backdrop = bp.id;

-- -- Recreate season view THIS IS an UPDATE TO ABOVE--
-- DROP VIEW season;

CREATE VIEW season AS
SELECT _tblseason.id, _tblseason.season_number, _tblseason.tvshowid, _tblseason.added, assets.local_path as poster
FROM _tblseason
LEFT OUTER JOIN assets ON _tblseason.poster = assets.id;

-- Create Unique Indexes -- --

CREATE UNIQUE INDEX season_idx ON _tblseason(season_number, tvshowid);

CREATE UNIQUE INDEX episode_idx ON episode(seasonid, episode_);

CREATE UNIQUE INDEX progress_idx ON progress(user_id, media_id);

CREATE UNIQUE INDEX genre_media_idx ON genre_media(genre_id, media_id);

CREATE UNIQUE INDEX media_posters_idx ON media_posters(media_id, asset_id);

CREATE UNIQUE INDEX media_backdrops_idx ON media_backdrops(media_id, asset_id);

CREATE UNIQUE INDEX media_idx ON _tblmedia(library_id, name, media_type) WHERE NOT _tblmedia.media_type = 'episode';

CREATE INDEX media_excl_ep_idx ON _tblmedia(name) WHERE NOT _tblmedia.media_type = 'episode';

DROP INDEX media_excl_ep_idx;