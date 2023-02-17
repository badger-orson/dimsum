CREATE OR REPLACE FUNCTION delete_season() 
RETURNS trigger AS $$
BEGIN
    DELETE FROM _tblseason WHERE _tblseason.id = OLD.id; 
    RETURN OLD; 
END; 
$$ LANGUAGE plpgsql;

--

CREATE TRIGGER season_delete
INSTEAD OF DELETE ON season
FOR EACH ROW
EXECUTE FUNCTION delete_season();

--

CREATE OR REPLACE FUNCTION delete_media()
RETURNS trigger AS $$
BEGIN
    DELETE FROM _tblmedia WHERE _tblmedia.id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

--

CREATE TRIGGER media_delete
INSTEAD OF DELETE ON media
FOR EACH ROW
EXECUTE FUNCTION delete_media();

--

CREATE OR REPLACE FUNCTION propagate_media_backdrops()
RETURNS trigger AS $$
BEGIN
    DELETE FROM assets WHERE id = OLD.asset_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

--

CREATE TRIGGER media_backdrops_propagate
AFTER DELETE ON media_backdrops
FOR EACH ROW
EXECUTE FUNCTION propagate_media_backdrops();

--

CREATE OR REPLACE FUNCTION propagate_media_posters()
RETURNS trigger AS $$
BEGIN
    DELETE FROM assets WHERE id = OLD.asset_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

--

CREATE TRIGGER media_posters_propagate
AFTER DELETE ON media_posters
FOR EACH ROW
EXECUTE FUNCTION propagate_media_posters();

--