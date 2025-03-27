import 'dart:math';

import 'package:flutter/material.dart';

Random random = Random();

class TravelDestination {
  final int id, price, review;
  final List image;
  final String name, description, category, location;
  final double rate;

  TravelDestination({
    required this.name,
    required this.price,
    required this.id,
    required this.category,
    required this.description,
    required this.review,
    required this.image,
    required this.rate,
    required this.location,
  });
}

List<TravelDestination> myDestination = [
  TravelDestination(
    id: 2,
    name: "Cristo Redentor",
    category: 'popular',
    image: [
      "https://aosviajantes.com.br/wp-content/uploads/2016/08/novo-cristo-redentor-corcovado-paineiras.jpg",
      "https://s2-oglobo.glbimg.com/LjRpYo4YPHqcALh_iy8HxPNq11o=/0x0:723x576/888x0/smart/filters:strip_icc()/i.s3.glbimg.com/v1/AUTH_da025474c0c44edd99332dddb09cabe8/internal_photos/bs/2022/m/w/zRXlsfQXyk4EVe5BLy5g/3.glbimg.com-v1-auth-0ae9f161c1ff459593599b7ffa1a1292-images-escenic-2022-3-19-21-1647736656268.jpg",
      "https://prefeitura.rio/wp-content/uploads/2021/10/Cristo-DePaula5.jpg"
    ],
    location: "Rio de Janeiro, RJ",
    review: random.nextInt(300) + 25,
    price: 999,
    description: "O Cristo Redentor é uma estátua de Jesus Cristo de 38 metros de altura, localizada no Morro do Corcovado, no Rio de Janeiro. É um símbolo do Brasil no exterior e uma das Novas 7 Maravilhas do Mundo.",
    rate: 4.9,
  ),
  TravelDestination(
    id: 7,
    price: 100,
    name: "Maracanã",
    image: [
      "https://media.tacdn.com/media/attractions-splice-spp-674x446/0b/27/5a/58.jpg",
      "https://visitrio.com.br/wp-content/uploads/2024/06/Descubra-o-Maracana-Historia-gloria-e-emocao-no-templo-do-Futebol-brasileiro.jpg",
      "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/18/42/2d/f6/photo0jpg.jpg?w=900&h=-1&s=1",
    ],
    review: random.nextInt(300) + 25,
    category: "popular",
    location: "Rio de Janeiro, RJ",
    description: "O Estádio Jornalista Mário Filho, mais conhecido como Maracanã, é um estádio de futebol com formato oval, localizado no Rio de Janeiro. É um dos maiores estádios do Brasil e um dos mais importantes do futebol brasileiro.",
    rate: 4.8,
  ),
  TravelDestination(
    id: 3,
    name: "Escadaria Selarón",
    review: random.nextInt(300) + 25,
    price: 599,
    category: 'recomend',
    image: [
      "https://freewalkertours.com/wp-content/uploads/Escalera-Selaron5-1.jpeg",
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRyA45iqytD-QbMo5tP4r7I3TnxiHQm_DA_KQ&s",
      "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/18/23/e8/81/escadaria-selaron.jpg?w=900&h=500&s=1",
    ],
    location: "Rio de Janeiro, RJ",
    description: "A Escadaria Selarón é uma obra de arte pública no Rio de Janeiro, Brasil, que liga os bairros de Santa Teresa e Lapa. É composta por 215 degraus coloridos e vibrantes, revestidos com azulejos de mais de 60 países. ",
    rate: 4.6,
  ),
  TravelDestination(
    id: 8,
    name: "Parque Lage",
    review: random.nextInt(300) + 25,
    price: 777,
    category: "popular",
    image: [
      "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/08/3b/fe/d5/parque-lage.jpg?w=1200&h=-1&s=1",
      "https://riodejaneiro.tur.br/wp-content/uploads/2024/12/parque-lage-111-1024x640.jpg",
      "https://pointer.com.br/blog/wp-content/uploads/2019/05/GettyImages-174964055-1-1024x683.jpg",
    ],
    location: "Rio de Janeiro, RJ",
    description: "O Parque Lage é um parque público no Rio de Janeiro, com mais de 52 hectares de área. É um dos principais pontos de encontro da cidade, e um lugar de inspiração e tranquilidade.",
    rate: 4.5,
  ),
  TravelDestination(
    id: 1,
    name: "Pão de açúcar",
    review: random.nextInt(300) + 25,
    price: 920,
    category: 'recomend',
    image: [
      "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/11/d7/5c/0d/vista-do-morro-da-urca.jpg?w=1200&h=900&s=1",
      "https://forbes.com.br/wp-content/uploads/2022/07/Pao-De-Acucar-Rio-De-Janeiro-Melhor-vista-do-mundo-1030x438.jpg",
      "https://www.smartriotour.com.br/wp-content/uploads/2017/05/Bondinho-Rio-de-Janeiro.jpg",
    ],
    location: "Rio de Janeiro, RJ",
    description: "O Pão de Açúcar é um dos cartões-postais mais famosos da cidade do Rio de Janeiro e é um destino turístico popular para pessoas de todo o mundo. Com uma altura de 396 metros, essa montanha rochosa oferece vistas panorâmicas deslumbrantes da cidade. É um destino obrigatório para qualquer pessoa que visite o Rio!",
    rate: 4.6,
  ),
  TravelDestination(
    id: 9,
    name: "Lagoa Rodrigo de Freitas",
    review: random.nextInt(300) + 25,
    category: "popular",
    price: 199,
    image: [
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT4pHrPIDdKlKpjwvr-hnCUw7Lw0gp_YIOF6A&s",
      "https://panoramadeviagem.com.br/wp-content/uploads/2020/11/o-que-conhecer-lagoa-rio.jpg",
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT5shPRfbHzpkqU_U5WdaNjw99zErPmeGTNWg&s",
    ],
    location: "Rio de Janeiro, RJ",
    description: "A Lagoa Rodrigo de Freitas é um ponto turístico do Rio de Janeiro, localizada na Zona Sul. É um lugar de encontro entre a natureza e a cidade, onde é possível praticar esportes aquáticos, passear, relaxar e saborear a gastronomia local. ",
    rate: 4.7,
  ),
  TravelDestination(
    id: 12,
    name: "Arcos da lapa",
    category: "recomend",
    review: random.nextInt(300) + 25,
    price: 499,
    image: [
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR8Z8KcPoEj66xDEqFfA_YRgFnwNL44B3ttTg&s",
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPldfh2AMFm5MXa8U0ae6TdYMx7nlM_er6sQ&s"
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQJ7WakijlUniugbsJc0xfXEU7HRbCq3V_6Uw&s",
    ],
    location: "Rio de Janeiro, RJ",
    description: "Os Arcos da Lapa, também conhecidos como Aqueduto da Carioca, são um conjunto de arcos em pedra e cal que se estendem por 270 metros de comprimento. São um dos cartões postais do Rio de Janeiro e um símbolo do Brasil colonial. ",
    rate: 4.8,
  ),
  TravelDestination(
    id: 14,
    name: "Porto maravilha ",
    review: random.nextInt(300) + 25,
    category: "recomend",
    price: 99,
    image: [
      "https://a.travel-assets.com/findyours-php/viewfinder/images/res70/191000/191614-Museu-Do-Amanh-.jpg",
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSypWh5UZKuS65cwcJYK-xoHLyNyV8lOcJhmw&s",
    ],
    location: "Rio de Janeiro, RJ",
    description: "O Porto Maravilha é um projeto de revitalização da região portuária do Rio de Janeiro, Brasil. O objetivo é transformar a área em um polo cultural, turístico e econômico.",
    rate: 4.7,
  ),
];

