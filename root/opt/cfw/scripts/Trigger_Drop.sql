DROP TRIGGER [TRIGGER_RecentlyReadingBookshelf];
DELETE FROM ShelfContent WHERE ShelfName = ' 最近読んでいる本棚';
DELETE FROM Shelf WHERE Name = ' 最近読んでいる本棚';
