import 'package:flutter/material.dart';

/*
   這邊配置完成時，必須到 main.dart 設定 route
*/
final List<MenuEntry> menuList = <MenuEntry>[
  MenuEntry('首頁', '/'),
  MenuEntry(
    '共通',
    '',
    <MenuEntry>[
      MenuEntry('車輛查詢', '/TVS0100004'),
      //MenuEntry('生產刷讀作業(暫)', '/TVS0100017'),
      //MenuEntry('存車維護作業(暫)', '/TVS0100016'),
    ],
  ),
  MenuEntry(
    '港口事業部',
    '',
    <MenuEntry>[
      MenuEntry('卸船作業', '/TVS0100002'),
      MenuEntry('盤點找車', '/TVS0100003'),
      MenuEntry('加油作業', '/TVS0100006'),
      MenuEntry('車輛儲區作業', '/TVS0100007'),
      MenuEntry('生產移車作業', '/TVS0100008'),
      MenuEntry('配件點檢作業', '/TVS0100005'),
      MenuEntry('配件檢查稽核', '/TVS0100012'),
      MenuEntry('車輛檢查作業', '/TVS0100010'),
      MenuEntry('存車維護作業', '/TVS0100024'),
    ],
  ),
  MenuEntry(
    '整一部',
    '',
    <MenuEntry>[
      MenuEntry('PDI 作業', '/'),
      MenuEntry('RETROFIT 作業', '/'),
      MenuEntry('鈑噴 作業', '/'),
      MenuEntry('底塗 作業', '/'),
    ],
  ),
  MenuEntry(
    '整二部',
    '',
    <MenuEntry>[
      MenuEntry('PDI 作業', '/TVS0100021'),
      MenuEntry('PDI 維修', '/TVS0100023'),
      MenuEntry('PDI 終檢確認', '/TVS0100022'),
    ],
  ),
  MenuEntry(
    '整三部',
    '',
    <MenuEntry>[
      MenuEntry('RETROFIT 作業', '/TVS0100020'),
      MenuEntry('底塗 作業', '/TVS0100025'),
    ],
  ),
  MenuEntry(
    '鈑噴部',
    '',
    <MenuEntry>[
      MenuEntry('估價拍照', '/TVS0100018'),
    ],
  ),
  MenuEntry(
    '底塗部',
    '',
    <MenuEntry>[
      MenuEntry('未確認', '/'),
    ],
  ),
  MenuEntry(
    '零件物流部',
    '',
    <MenuEntry>[
      MenuEntry('未確認', '/'),
    ],
  ),
  MenuEntry(
    'V2 系統',
    '',
    <MenuEntry>[
      MenuEntry('車輛儲區作業', '/TVS0200001'),
    ],
  ),
  MenuEntry(
    '工具',
    '',
    <MenuEntry>[
      MenuEntry('拍照上傳測試', '/TVS0100019'),
    ],
  ),
];

Widget buildMenu(BuildContext context) {
  return Drawer(
    child: SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) =>
              MenuItem(menuList[index]),
          itemCount: menuList.length,
        ),
      ),
    ),
  );
}

class MenuEntry {
  MenuEntry(this.title, this.url, [this.children = const <MenuEntry>[]]);

  final String title;
  final String url;
  final List<MenuEntry> children;
}

class MenuItem extends StatelessWidget {
  const MenuItem(this.entry);

  final MenuEntry entry;

  Widget _buildTiles(BuildContext context, MenuEntry root) {
    if (root.children.isEmpty) {
      return Container(
        color: Colors.orange[200],
        child: ListTile(
            contentPadding: const EdgeInsets.all(3.0),
            leading: Icon(Icons.home),
            title: Text(
              root.title,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // Navigator.pushNamed(context, '/');
              // Navigator.popAndPushNamed(context, '/');
              // Navigator.pushReplacementNamed(context, '/');
              // Navigator.pushReplacementNamed(context, '/');
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => route == null);
            }),
      );
    } else {
      return ExpansionTile(
          tilePadding: const EdgeInsets.all(3.0),
          childrenPadding: const EdgeInsets.only(left: 45.0),
          leading: Icon(Icons.apps),
          backgroundColor: Colors.grey[200],
          key: PageStorageKey<MenuEntry>(root),
          title: Container(
            margin: const EdgeInsets.all(0.0),
            padding: const EdgeInsets.all(0.0),
            child: Text(
              root.title,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          children: _buildChildren(context, root));
    }
  }

  _buildChildren(BuildContext context, MenuEntry root) {
    List<Widget> list = [];

    for (MenuEntry item in root.children) {
      //判斷權限
      list.add(
        new Container(
          decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.white, width: 2.0))),
          child: ListTile(
              dense: true,
              title: new Text(
                item.title,
                style: new TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, item.url,
                    (Route<dynamic> route) {
                  if (route.settings.name == '/main')
                    return true;
                  else
                    return false;
                });
              }),
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(context, entry);
  }
}
