import 'package:flutter_test/flutter_test.dart';
import 'package:notsdaleit/features/forms/form_model.dart';
import 'package:notsdaleit/features/forms/insert_image.dart';

/// Görsel dosyası temizliğinin **hangi dosyaların kullanımda olduğunu**
/// bulması.
///
/// Bu fonksiyon yanlış cevap verirse sonucu doğrudan veri kaybıdır: kullanıcı
/// bir notu kalıcı silince, hâlâ başka notta duran bir fotoğraf da diskten
/// silinebilir (notu çoğaltmak aynı dosyayı gösterir). Bu yüzden "kullanımda"
/// tarafında cömert olmak zorunda.
void main() {
  test('gövdedeki görsel bloklarının dosya adlarını bulur', () {
    final body = FormDoc([
      AreaBlock(value: 'yazı'),
      ImageBlock(file: 'a.jpg', aspect: 1),
      ImageBlock(file: 'b.png', aspect: 1),
    ]).encode();

    expect(imageNamesInBody(body), {'a.jpg', 'b.png'});
  });

  test('görselsiz gövdede boş küme döner', () {
    final body = FormDoc([AreaBlock(value: 'yalnız yazı')]).encode();
    expect(imageNamesInBody(body), isEmpty);
  });

  test('Quill (serbest) notta boş küme döner — çökmez', () {
    expect(imageNamesInBody('[{"insert":"merhaba\\n"}]'), isEmpty);
    expect(imageNamesInBody(''), isEmpty);
    expect(imageNamesInBody('{bozuk'), isEmpty);
  });

  test('boş dosya adı kullanımda sayılmaz', () {
    final body = FormDoc([ImageBlock(file: '', aspect: 1)]).encode();
    expect(imageNamesInBody(body), isEmpty);
  });

  test('aynı dosya iki blokta geçse de tek kez sayılır', () {
    final body = FormDoc([
      ImageBlock(file: 'x.jpg', aspect: 1),
      ImageBlock(file: 'x.jpg', aspect: 1),
    ]).encode();
    expect(imageNamesInBody(body), {'x.jpg'});
  });
}
