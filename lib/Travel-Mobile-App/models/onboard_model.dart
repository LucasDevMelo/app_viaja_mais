class OnboardModel {
  String image, name;

  OnboardModel({required this.image, required this.name});
}

List<OnboardModel> onboarding = [
   OnboardModel(
    image: 'https://media.istockphoto.com/id/478317169/photo/botafogo-neighborhood.jpg?s=612x612&w=0&k=20&c=wQkYtezKNvOnHYa6nHYCv0tvyqw6k66rIqZoP78tklM=',
    name: 'Explore o Brasil conosco.',
  ),
  OnboardModel(
    image: 'https://i.pinimg.com/736x/cc/d8/25/ccd825d5af01e4c4e31ab58ddb8c8d37.jpg',
    name: "O céu único de Brasília",
  ),
  OnboardModel(
    image: 'https://www.tatiluft.com.br/wp-content/uploads/2021/05/02.-Dois-irma%CC%83os.jpg',
    name: 'A beleza de Noronha',
  ),
];