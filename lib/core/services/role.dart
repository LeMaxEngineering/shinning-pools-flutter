enum UserRole {
  root,
  admin,
  worker,
  customer;
 
  bool get isRoot => this == UserRole.root;
  bool get isAdmin => this == UserRole.admin;
  bool get isWorker => this == UserRole.worker;
  bool get isCustomer => this == UserRole.customer;
} 