/// Long-form copy paired with overview images on the News screen.
class NewsVisualStory {
  const NewsVisualStory({
    required this.assetPath,
    required this.title,
    required this.paragraphs,
  });

  final String assetPath;
  final String title;
  final List<String> paragraphs;
}

const kNewsVisualStories = <NewsVisualStory>[
  NewsVisualStory(
    assetPath: 'assets/images/overview_nist.jpg',
    title: 'NIST and the post-quantum standards story',
    paragraphs: [
      'The National Institute of Standards and Technology (NIST) ran a public, multi-year competition to select algorithms that should replace RSA, finite-field Diffie–Hellman, and elliptic-curve schemes once large-scale quantum computers exist. The winners map to what you now see in federal profiles: ML-KEM (from Kyber) for key encapsulation, ML-DSA (from Dilithium) for general-purpose signatures, and SLH-DSA (from SPHINCS+) for conservative hash-based signing where larger signatures are acceptable.',
      'The 2024 publication of FIPS 203, 204, and 205 matters because it gives vendors, regulators, and enterprises a concrete target for new libraries, hardware security modules, and procurement rules. That does not mean Bitcoin “automatically” adopts NIST curves or Dilithium tomorrow: the chain’s consensus rules are separate from TLS or VPN stacks. But the same organizations that custody bitcoin, run exchanges, and build wallets will be upgrading everything around the chain—so the NIST timeline sets expectations for how fast the broader cryptography ecosystem moves.',
      'For Bitcoin specifically, the interesting tension is between **off-chain** systems (where you might plug in PQC for transport and authentication quickly) and **on-chain** script, where any new signature type requires a careful soft fork, reference implementations, and years of review. NIST standardization is therefore a backdrop: it tells you what the world will expect from “modern crypto,” while Bitcoin’s engineers still have to argue about witness versions, backward compatibility, and migration incentives.',
      'None of this replaces scenario modeling. Standards reduce interoperability risk; they do not tell you whether quantum capability or user migration wins the race in a given decade. Use the toolkit’s simulator to stress **break year** and **migration** assumptions—the NIST story is why hardware and software vendors will feel pressure to ship PQC even before a quantum machine breaks a key in the wild.',
    ],
  ),
  NewsVisualStory(
    assetPath: 'assets/images/overview_ibm_quantum.jpg',
    title: 'IBM-style hardware milestones vs breaking ECDSA',
    paragraphs: [
      'IBM and other labs publish processor generations with eye-catching **physical** qubit counts—Condor, Heron, and roadmap slides that stretch into the 2030s. Those numbers describe chips and systems used for chemistry simulation, error-correction research, and benchmarking. They are not the same as “logical qubits” that would execute a full fault-tolerant Shor instance against secp256k1 at scale, and they are not a direct readout of calendar time until a key is broken.',
      'Useful cryptanalysis against elliptic-curve discrete logarithms needs sustained, error-corrected computation. Roadmap targets (for example, public IBM materials discussing thousands of logical qubits later this decade) are **aspirational engineering goals**. They can move earlier or later as materials science, control electronics, and decoding algorithms improve. That is why the app treats “quantum break year” as a parameter you sweep rather than a single point estimate from a press release.',
      'The milestone chart on this screen shows documented **hardware announcements** on a log scale; the race chart shows a **conceptual** overlap between quantum capability and migration. Neither chart claims that a particular IBM chip breaks Bitcoin next Tuesday. They orient you: hardware is advancing quickly in the lab, while Bitcoin migration is a social-technical process that can lag or lead depending on policy, UX, and incentives.',
      'When you read news about qubit records, pair it with this distinction: **laboratory scale** versus **cryptanalytic reality** versus **protocol migration**. The toolkit is built to make that third leg—migration speed and vulnerable share—as explicit as the quantum curve, because headlines about chips alone will not tell you whether funds are safe in the 2040s.',
    ],
  ),
];
