class TodoList {
  String added_time; //입력된 연, 월, 일, 시, 분, 초가 모두 기록되어 PK처럼 작동함
  String? image; // 이미지 url
  String title; // 할 일 이름

  TodoList({
    required this.added_time,
    this.image,
    required this.title
  });
}